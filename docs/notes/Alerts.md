## Receiving Alerts via Logz.io Webhooks

Logz.io allows the definition of endpoints to be used (via HTTP requests) when a new alert is generated.

In the case of this project, we want to receive the base alert information when one is generated.

Logz.io provides several variables that can be sent via the webhook mechanism. It is recommended to include at least the following:

| Parameter                              | Description                                                                                     |
|----------------------------------------|-------------------------------------------------------------------------------------------------|
| `{{alert_title}}`                      | Title of the triggered alert                                                                    |
| `{{alert_description}}`                | Alert description                                                                               |
| `{{alert_definition_id}}`              | Unique alert ID                                                                                 |
| `{{alert_event_id}}`                   | Unique ID of the triggered alert instance                                                      |
| `{{alert_severity}}`                   | Severity of the triggered alert                                                                |
| `{{alert_samples}}`                    | Prints a readable sample of the raw logs that caused the alert to trigger (String format, up to 10 logs) |
| `["{{alert_samples_json}}"]`           | Prints a machine-friendly sample of the raw logs that caused the alert to trigger (JSON format, up to 10 logs) |
| `{{alert_tags}}`                       | A comma-separated list of tags assigned to the alert: That is, tag1, tag2, tag3               |


([Full Table Reference](https://docs.logz.io/docs/user-guide/integrations/notification-endpoints/custom-endpoints/))

These variables ensure that the webhook delivers essential information for understanding and responding to the alert effectively.

We define our payload as:

```json
{
    "alert_id": "{{alert_definition_id}}",
    "alert_title": "{{alert_title}}",
    "alert_description": "{{alert_description}}",
    "alert_severity": "{{alert_severity}}",
    "alert_event_samples": "{{alert_samples}}",
    "alert_tags":["{{alert_tags_json}}"],
    "start": "{{alert_timeframe_start}}",
    "end": "{{alert_timeframe_end}}"
}
```

Note that the requests must contain in its headers a `Bearer` token, generate by the application by a given account.