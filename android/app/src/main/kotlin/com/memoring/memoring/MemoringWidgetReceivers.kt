package com.memoring.memoring

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MemoringSmallWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.memoring_widget_small).apply {
                val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, openApp)
                setTextViewText(
                    R.id.date_label,
                    widgetData.getString("date_label", "") ?: "",
                )
                setTextViewText(
                    R.id.count_label,
                    widgetData.getString("count_label", "0 / 0") ?: "0 / 0",
                )
                setProgressBar(
                    R.id.progress,
                    100,
                    widgetData.getInt("progress", 0),
                    false,
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class MemoringMediumWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val itemRows = intArrayOf(R.id.item_0, R.id.item_1, R.id.item_2, R.id.item_3)
        val checks = intArrayOf(R.id.check_0, R.id.check_1, R.id.check_2, R.id.check_3)
        val titles = intArrayOf(R.id.title_0, R.id.title_1, R.id.title_2, R.id.title_3)
        val categories = intArrayOf(R.id.category_0, R.id.category_1, R.id.category_2, R.id.category_3)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.memoring_widget_medium).apply {
                val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, openApp)
                setTextViewText(
                    R.id.date_label,
                    widgetData.getString("date_label", "") ?: "",
                )
                setTextViewText(
                    R.id.count_label,
                    widgetData.getString("count_label", "0 / 0") ?: "0 / 0",
                )

                val empty = widgetData.getBoolean("empty", true)
                val count = widgetData.getInt("item_count", 0)
                setViewVisibility(R.id.empty_label, if (empty) View.VISIBLE else View.GONE)

                for (index in 0 until 4) {
                    val visible = !empty && index < count
                    setViewVisibility(itemRows[index], if (visible) View.VISIBLE else View.GONE)
                    if (!visible) {
                        continue
                    }
                    val title = widgetData.getString("item_${index}_title", "") ?: ""
                    val category = widgetData.getString("item_${index}_category", "") ?: ""
                    val done = widgetData.getBoolean("item_${index}_done", false)
                    val id = widgetData.getString("item_${index}_id", "") ?: ""
                    setTextViewText(titles[index], title)
                    setTextViewText(categories[index], category)
                    setImageViewResource(
                        checks[index],
                        if (done) R.drawable.memoring_widget_check_on else R.drawable.memoring_widget_check_off,
                    )
                    if (id.isNotEmpty()) {
                        val toggle = HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse("memoring://toggle?id=$id"),
                        )
                        setOnClickPendingIntent(checks[index], toggle)
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
