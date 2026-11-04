package com.tasksforallah.tasks_for_allah

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/** Home screen widget: "Ihsan — today's prayers" for the active profile. */
class IhsanWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = HomeWidgetPlugin.getData(context)
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.ihsan_widget).apply {
                setTextViewText(R.id.widget_person, data.getString("person", "") ?: "")
                setTextViewText(R.id.widget_count, data.getString("count", "0/5 prayed today") ?: "0/5")
                setTextViewText(R.id.widget_points, data.getString("points", "") ?: "")
                setTextViewText(R.id.widget_fajr, data.getString("mark_fajr", "FAJ\n·") ?: "FAJ\n·")
                setTextViewText(R.id.widget_dhuhr, data.getString("mark_dhuhr", "DHU\n·") ?: "DHU\n·")
                setTextViewText(R.id.widget_asr, data.getString("mark_asr", "ASR\n·") ?: "ASR\n·")
                setTextViewText(R.id.widget_maghrib, data.getString("mark_maghrib", "MAG\n·") ?: "MAG\n·")
                setTextViewText(R.id.widget_isha, data.getString("mark_isha", "ISH\n·") ?: "ISH\n·")
                if (launchIntent != null) {
                    setOnClickPendingIntent(
                        R.id.widget_root,
                        PendingIntent.getActivity(context, 0, launchIntent, flags),
                    )
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
