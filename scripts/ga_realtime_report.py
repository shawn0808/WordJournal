#!/usr/bin/env python3
"""
GA4 Realtime Report: Page views and downloads (last 30 min).

Setup:
1. pip install google-analytics-data
2. Create a service account in Google Cloud Console
   - Enable "Google Analytics Data API"
   - Create credentials > Service account > Download JSON key
3. Add the service account email as Viewer in GA4 (Admin > Property > Property access management)
4. Get your GA4 Property ID (Admin > Property Settings - it's a numeric ID like 123456789)
5. Set env vars:
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   export GA4_PROPERTY_ID="123456789"
"""
import os
import sys

try:
    from google.analytics.data_v1beta import BetaAnalyticsDataClient
    from google.analytics.data_v1beta.types import (
        Dimension,
        Metric,
        RunRealtimeReportRequest,
    )
except ImportError:
    print("Install: pip install google-analytics-data")
    sys.exit(1)

PROPERTY_ID = os.environ.get("GA4_PROPERTY_ID", "")
if not PROPERTY_ID:
    print("Set GA4_PROPERTY_ID (numeric, from GA4 Admin > Property Settings)")
    sys.exit(1)


def run_realtime_report():
    client = BetaAnalyticsDataClient()

    # Report 1: Totals - active users, page views, events (no dimension = totals)
    request = RunRealtimeReportRequest(
        property=f"properties/{PROPERTY_ID}",
        metrics=[
            Metric(name="activeUsers"),
            Metric(name="screenPageViews"),
            Metric(name="eventCount"),
        ],
    )
    response = client.run_realtime_report(request)

    print("\n=== Realtime (last 30 min) ===\n")
    if response.rows:
        row = response.rows[0]
        users = int(row.metric_values[0].value)
        views = int(row.metric_values[1].value)
        events = int(row.metric_values[2].value)
        print(f"  Active users: {users}")
        print(f"  Page views:   {views}")
        print(f"  Total events: {events}")

    # Report 2: Events by name (download_click, page_view, etc.)
    request2 = RunRealtimeReportRequest(
        property=f"properties/{PROPERTY_ID}",
        dimensions=[Dimension(name="eventName")],
        metrics=[Metric(name="eventCount")],
    )
    response2 = client.run_realtime_report(request2)

    print("\n=== Events (last 30 min) ===\n")
    for row in response2.rows:
        event_name = row.dimension_values[0].value
        count = int(row.metric_values[0].value)
        print(f"  {event_name}: {count}")
        if event_name == "download_click":
            print(f"    -> Downloads: {count}")

    print()


if __name__ == "__main__":
    run_realtime_report()
