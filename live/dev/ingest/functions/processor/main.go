// Command processor validates a CSV batch from the landing bucket and writes
// its readings to the readings table. S3 invokes it for each new batch.
package main

import (
	"context"
	"encoding/csv"
	"errors"
	"fmt"
	"log"
	"math"
	"net/url"
	"os"
	"slices"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

var header = []string{"line_id", "recorded_at", "temperature_c", "cycle_time_s", "reject_rate"}

// Matches the landing bucket's expiry of raw batches.
const retention = 7 * 24 * time.Hour

var (
	s3Client *s3.Client
	db       *dynamodb.Client
	table    = os.Getenv("TABLE_NAME")
)

func main() {
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	s3Client = s3.NewFromConfig(cfg)
	db = dynamodb.NewFromConfig(cfg)
	lambda.Start(handler)
}

// handler returns an error for any invalid batch, so Lambda retries it and
// then sends the event to the dead-letter queue.
func handler(ctx context.Context, event events.S3Event) error {
	for _, record := range event.Records {
		if err := process(ctx, record.S3.Bucket.Name, record.S3.Object.Key); err != nil {
			return err
		}
	}
	return nil
}

func process(ctx context.Context, bucket, encodedKey string) error {
	// S3 event notifications URL-encode object keys.
	key, err := url.QueryUnescape(encodedKey)
	if err != nil {
		return fmt.Errorf("decode key %q: %w", encodedKey, err)
	}

	obj, err := s3Client.GetObject(ctx, &s3.GetObjectInput{Bucket: aws.String(bucket), Key: aws.String(key)})
	if err != nil {
		return fmt.Errorf("get %s: %w", key, err)
	}
	defer obj.Body.Close()

	rows, err := csv.NewReader(obj.Body).ReadAll()
	if err != nil {
		return fmt.Errorf("read %s: %w", key, err)
	}

	// The whole batch is validated before any of it is written. Retries put
	// the same keys again, so they never duplicate readings.
	items, err := parse(rows, time.Now().Add(retention).Unix())
	if err != nil {
		return fmt.Errorf("validate %s: %w", key, err)
	}
	for _, item := range items {
		if _, err := db.PutItem(ctx, &dynamodb.PutItemInput{TableName: aws.String(table), Item: item}); err != nil {
			return fmt.Errorf("put reading from %s: %w", key, err)
		}
	}
	log.Printf("stored %d readings from %s", len(items), key)
	return nil
}

func parse(rows [][]string, expiresAt int64) ([]map[string]types.AttributeValue, error) {
	if len(rows) == 0 || !slices.Equal(rows[0], header) {
		return nil, errors.New("missing or unexpected header")
	}

	// csv.Reader has already checked that every row has as many fields as the header.
	items := make([]map[string]types.AttributeValue, 0, len(rows)-1)
	for i, row := range rows[1:] {
		n := i + 2 // 1-based, counting the header
		if row[0] == "" {
			return nil, fmt.Errorf("row %d: empty line_id", n)
		}
		if _, err := time.Parse(time.RFC3339, row[1]); err != nil {
			return nil, fmt.Errorf("row %d: recorded_at is not an RFC 3339 timestamp: %q", n, row[1])
		}

		item := map[string]types.AttributeValue{
			"line_id":     &types.AttributeValueMemberS{Value: row[0]},
			"recorded_at": &types.AttributeValueMemberS{Value: row[1]},
			"expires_at":  &types.AttributeValueMemberN{Value: strconv.FormatInt(expiresAt, 10)},
		}
		for j, name := range header[2:] {
			v, err := strconv.ParseFloat(row[j+2], 64)
			if err != nil || math.IsNaN(v) || math.IsInf(v, 0) {
				return nil, fmt.Errorf("row %d: %s is not a number: %q", n, name, row[j+2])
			}
			item[name] = &types.AttributeValueMemberN{Value: strconv.FormatFloat(v, 'f', -1, 64)}
		}
		items = append(items, item)
	}
	return items, nil
}
