package com.memoring.memoring

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

class MemoringWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        appWidgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.memoring_widget_configure)
        val list = findViewById<LinearLayout>(R.id.page_list)
        val prefs = MemoringWidgetData.prefs(this)
        val selected = MemoringWidgetData.pageIdFor(prefs, appWidgetId)
        MemoringWidgetData.pages(prefs).forEach { page ->
            list.addView(pageButton(page.name, page.id == selected) {
                MemoringWidgetData.savePageId(prefs, appWidgetId, page.id)
                MemoringWidgetData.notifyWidgets(this, appWidgetId)
                setResult(
                    RESULT_OK,
                    Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
                )
                finish()
            })
        }
    }

    private fun pageButton(
        name: String,
        selected: Boolean,
        onClick: () -> Unit,
    ): TextView {
        val padH = dp(18)
        val padV = dp(14)
        return TextView(this).apply {
            text = name
            setTextColor(if (selected) 0xFF5A463E.toInt() else 0xFF5A463E.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setPadding(padH, padV, padH, padV)
            gravity = Gravity.CENTER
            setBackgroundResource(
                if (selected) {
                    R.drawable.memoring_widget_page_selected
                } else {
                    R.drawable.memoring_widget_page_choice
                },
            )
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            )
            params.topMargin = dp(8)
            layoutParams = params
            setOnClickListener { onClick() }
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()
    }
}
