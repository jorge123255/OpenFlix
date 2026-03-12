package tvguide

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"
)

func TestProviderLookup(t *testing.T) {
	if os.Getenv("OPENFLIX_TVGUIDE_INTEGRATION") != "1" {
		t.Skip("set OPENFLIX_TVGUIDE_INTEGRATION=1 to run live TVGuide integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := NewClient()
	providers, err := client.GetProvidersByZip(ctx, "60601")
	if err != nil {
		t.Fatalf("Error: %v", err)
	}
	fmt.Printf("Found %d providers\n", len(providers))
	for i, p := range providers {
		if i < 5 {
			fmt.Printf("  %d - %s (%s)\n", p.ID, p.Name, p.Type)
		}
	}
	if len(providers) == 0 {
		t.Fatal("Expected providers")
	}
}

func TestScheduleFetch(t *testing.T) {
	if os.Getenv("OPENFLIX_TVGUIDE_INTEGRATION") != "1" {
		t.Skip("set OPENFLIX_TVGUIDE_INTEGRATION=1 to run live TVGuide integration tests")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client := NewClient()
	result, err := client.GetSchedule(ctx, "9166050689", 120)
	if err != nil {
		t.Fatalf("Error: %v", err)
	}
	fmt.Printf("Got %d channels in %v\n", len(result.Channels), result.Duration)

	total, newCount, liveCount := 0, 0, 0
	for _, ch := range result.Channels {
		for _, sched := range ch.ProgramSchedules {
			total++
			flags := DecodeAiringFlags(sched.AiringAttrib)
			if flags.IsNew {
				newCount++
			}
			if flags.IsLive {
				liveCount++
			}
		}
	}
	fmt.Printf("Total: %d programs, NEW: %d, LIVE: %d\n", total, newCount, liveCount)

	// Convert
	programs, channelCount := ConvertToPrograms(result, nil, "9166050689")
	fmt.Printf("Converted %d programs across %d channels\n", len(programs), channelCount)

	// Show sample NEW
	for _, p := range programs {
		if p.IsNew {
			fmt.Printf("\nSample NEW: %s on %s (ch %s)\n", p.Title, p.CallSign, p.ChannelNo)
			fmt.Printf("  %s - %s\n", p.Start.Format(time.Kitchen), p.End.Format(time.Kitchen))
			fmt.Printf("  Category: %s, Rating: %s\n", p.Category, p.Rating)
			break
		}
	}

	if total == 0 {
		t.Fatal("Expected programs")
	}
}
