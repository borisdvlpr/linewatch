// Command simulator writes one CSV batch of production-line readings to the
// landing bucket. EventBridge Scheduler invokes it every 30 minutes.
package main

import (
	"bytes"
	"context"
	"encoding/csv"
	"fmt"
	"log"
	"math/rand/v2"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// Five readings per line keep a batch of a few lines well inside the readings
// table's 5 WCU.
const readingsPerLine = 5

var (
	client *s3.Client
	bucket = os.Getenv("BUCKET_NAME")
	lines  = strings.Split(os.Getenv("LINES"), ",")
)

func main() {
	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	client = s3.NewFromConfig(cfg)
	lambda.Start(handler)
}

func handler(ctx context.Context) error {
	now := time.Now().UTC().Truncate(time.Second)
	body, err := batch(now)
	if err != nil {
		return err
	}

	key := "batches/" + now.Format("20060102T150405Z") + ".csv"
	_, err = client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(body),
		ContentType: aws.String("text/csv"),
	})
	if err != nil {
		return fmt.Errorf("put %s: %w", key, err)
	}
	log.Printf("wrote %d readings to %s", len(lines)*readingsPerLine, key)
	return nil
}

// batch returns readings one minute apart, ending at now, for every line.
func batch(now time.Time) ([]byte, error) {
	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	w.Write([]string{"line_id", "recorded_at", "temperature_c", "cycle_time_s", "reject_rate"})
	for _, line := range lines {
		for i := range readingsPerLine {
			at := now.Add(time.Duration(i-readingsPerLine+1) * time.Minute)
			w.Write([]string{
				line,
				at.Format(time.RFC3339),
				fmt.Sprintf("%.2f", 70+rand.NormFloat64()*2),
				fmt.Sprintf("%.2f", 30+rand.NormFloat64()),
				fmt.Sprintf("%.4f", rand.Float64()*0.05),
			})
		}
	}
	w.Flush()
	return buf.Bytes(), w.Error()
}
