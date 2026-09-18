package com.memoring.memoring

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.text.SpannableString
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import android.text.style.StrikethroughSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject

data class WidgetPage(val id: String, val name: String)

object MemoringWidgetData {
    private const val inboxId = "inbox"

    fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    }

    fun pages(prefs: SharedPreferences): List<WidgetPage> {
        val raw = prefs.getString("pages_json", null)
        if (raw.isNullOrBlank()) {
            return listOf(WidgetPage(inboxId, "오늘"))
        }
        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val id = item.optString("id")
                    val name = item.optString("name")
                    if (id.isNotEmpty() && name.isNotEmpty()) {
                        add(WidgetPage(id, name))
                    }
                }
            }.ifEmpty { listOf(WidgetPage(inboxId, "오늘")) }
        } catch (_: Exception) {
            listOf(WidgetPage(inboxId, "오늘"))
        }
    }

    fun pageIdFor(prefs: SharedPreferences, widgetId: Int): String {
        return prefs.getString("widget_page_$widgetId", inboxId) ?: inboxId
    }

    fun savePageId(prefs: SharedPreferences, widgetId: Int, pageId: String) {
        prefs.edit().putString("widget_page_$widgetId", pageId).apply()
    }

    fun snapshot(prefs: SharedPreferences, pageId: String): JSONObject? {
        val raw = prefs.getString("snapshot_$pageId", null)
            ?: prefs.getString("snapshot_$inboxId", null)
        if (raw.isNullOrBlank()) {
            return null
        }
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    fun bindSmall(context: Context, prefs: SharedPreferences, widgetId: Int): RemoteViews {
        val pageId = pageIdFor(prefs, widgetId)
        val data = snapshot(prefs, pageId)
        val views = RemoteViews(context.packageName, R.layout.memoring_widget_small)
        val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.widget_root, openApp)
        views.setTextViewText(
            R.id.title_label,
            data?.optString("title_progress")
                ?: context.getString(R.string.widget_today_progress),
        )
        views.setTextViewText(R.id.date_label, data?.optString("date_label").orEmpty())
        views.setTextViewText(
            R.id.count_label,
            data?.optString("count_label") ?: "0 / 0",
        )
        views.setProgressBar(R.id.progress, 100, data?.optInt("progress", 0) ?: 0, false)
        return views
    }

    fun bindMedium(context: Context, prefs: SharedPreferences, widgetId: Int): RemoteViews {
        val pageId = pageIdFor(prefs, widgetId)
        val data = snapshot(prefs, pageId)
        val views = RemoteViews(context.packageName, R.layout.memoring_widget_medium)
        val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.widget_root, openApp)
        views.setTextViewText(
            R.id.title_label,
            data?.optString("title_list")
                ?: context.getString(R.string.widget_today_list),
        )
        views.setTextViewText(R.id.date_label, data?.optString("date_label").orEmpty())
        views.setTextViewText(
            R.id.count_label,
            data?.optString("count_label") ?: "0 / 0",
        )

        val items = data?.optJSONArray("items") ?: JSONArray()
        val empty = data?.optBoolean("empty", items.length() == 0) ?: true
        views.setViewVisibility(R.id.empty_label, if (empty) View.VISIBLE else View.GONE)

        val itemRows = intArrayOf(R.id.item_0, R.id.item_1, R.id.item_2, R.id.item_3)
        val checks = intArrayOf(R.id.check_0, R.id.check_1, R.id.check_2, R.id.check_3)
        val titles = intArrayOf(R.id.title_0, R.id.title_1, R.id.title_2, R.id.title_3)
        val dailies = intArrayOf(R.id.daily_0, R.id.daily_1, R.id.daily_2, R.id.daily_3)
        val categories = intArrayOf(R.id.category_0, R.id.category_1, R.id.category_2, R.id.category_3)

        for (index in 0 until 4) {
            val visible = !empty && index < items.length()
            views.setViewVisibility(itemRows[index], if (visible) View.VISIBLE else View.GONE)
            if (!visible) {
                continue
            }
            val item = items.optJSONObject(index) ?: JSONObject()
            val title = item.optString("title")
            val done = item.optBoolean("done")
            val repeats = item.optBoolean("repeats")
            val id = item.optString("id")
            views.setTextViewText(titles[index], titledText(title, done))
            views.setTextViewText(categories[index], item.optString("category"))
            views.setViewVisibility(dailies[index], if (repeats) View.VISIBLE else View.GONE)
            views.setImageViewResource(
                checks[index],
                if (done) R.drawable.memoring_widget_check_on else R.drawable.memoring_widget_check_off,
            )
            if (id.isNotEmpty()) {
                val toggle = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("memoring://toggle?id=$id"),
                )
                views.setOnClickPendingIntent(checks[index], toggle)
            }
        }
        return views
    }

    fun bindMemo(context: Context, prefs: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.memoring_widget_memo)
        val openApp = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.widget_root, openApp)
        val data = memo(prefs)
        val empty = data?.optBoolean("empty", true) ?: true
        views.setViewVisibility(R.id.empty_label, if (empty) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.title_label, if (empty) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.body_label, if (empty) View.GONE else View.VISIBLE)
        if (!empty && data != null) {
            views.setTextViewText(R.id.title_label, data.optString("title"))
            views.setTextViewText(R.id.body_label, data.optString("body"))
        }
        return views
    }

    fun memo(prefs: SharedPreferences): JSONObject? {
        val raw = prefs.getString("memo_json", null)
        if (raw.isNullOrBlank()) {
            return null
        }
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }

    fun notifyWidgets(context: Context, widgetId: Int) {
        val manager = AppWidgetManager.getInstance(context)
        val small = ComponentName(context, MemoringSmallWidgetReceiver::class.java)
        val medium = ComponentName(context, MemoringMediumWidgetReceiver::class.java)
        val memo = ComponentName(context, MemoringMemoWidgetReceiver::class.java)
        val ids = intArrayOf(widgetId)
        context.sendBroadcast(
            Intent(context, MemoringSmallWidgetReceiver::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
        )
        context.sendBroadcast(
            Intent(context, MemoringMediumWidgetReceiver::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
        )
        context.sendBroadcast(
            Intent(context, MemoringMemoWidgetReceiver::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            },
        )
        manager.notifyAppWidgetViewDataChanged(manager.getAppWidgetIds(small), R.id.widget_root)
        manager.notifyAppWidgetViewDataChanged(manager.getAppWidgetIds(medium), R.id.widget_root)
        manager.notifyAppWidgetViewDataChanged(manager.getAppWidgetIds(memo), R.id.widget_root)
    }

    private fun titledText(title: String, done: Boolean): CharSequence {
        if (!done || title.isEmpty()) {
            return title
        }
        return SpannableString(title).apply {
            setSpan(StrikethroughSpan(), 0, title.length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            setSpan(
                ForegroundColorSpan(Color.parseColor("#8D7A72")),
                0,
                title.length,
                Spanned.SPAN_EXCLUSIVE_EXCLUSIVE,
            )
        }
    }
}
