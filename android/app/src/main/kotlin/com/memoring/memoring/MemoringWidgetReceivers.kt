package com.memoring.memoring

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MemoringSmallWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views: RemoteViews = MemoringWidgetData.bindSmall(context, widgetData, widgetId)
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
        appWidgetIds.forEach { widgetId ->
            val views: RemoteViews = MemoringWidgetData.bindMedium(context, widgetData, widgetId)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

class MemoringMemoWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views: RemoteViews = MemoringWidgetData.bindMemo(context, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
