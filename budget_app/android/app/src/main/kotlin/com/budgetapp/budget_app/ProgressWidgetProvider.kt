package com.budgetapp.budget_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class ProgressWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            ProgressWidgetConfigStore.clear(context, widgetId)
        }
    }

    companion object {
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, ProgressWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            for (widgetId in ids) {
                updateAppWidget(context, manager, widgetId)
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val views = RemoteViews(context.packageName, R.layout.progress_widget)
            val type = ProgressWidgetConfigStore.readType(context, appWidgetId)
            val itemId = ProgressWidgetConfigStore.readItemId(context, appWidgetId)

            if (type == null || itemId == null) {
                bindPlaceholder(context, views, appWidgetId)
            } else {
                val item = when (type) {
                    TYPE_GOAL -> WidgetSnapshotHelper.findGoal(context, itemId)
                    TYPE_LOAN -> WidgetSnapshotHelper.findLoan(context, itemId)
                    else -> null
                }

                if (item == null) {
                    bindMissing(context, views, appWidgetId)
                } else {
                    bindItem(context, views, appWidgetId, type, item)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun bindItem(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
            type: String,
            item: WidgetProgressItem,
        ) {
            val isLoan = type == TYPE_LOAN
            views.setTextViewText(R.id.widget_icon, item.icon)
            views.setTextViewText(R.id.widget_name, item.name)
            views.setTextViewText(
                R.id.widget_type_label,
                if (isLoan) "Loan" else "Goal",
            )
            views.setTextViewText(R.id.widget_percent, "${item.progress}%")
            views.setTextViewText(R.id.widget_subtitle, item.subtitle)
            views.setProgressBar(
                R.id.widget_progress,
                100,
                item.progress,
                false,
            )

            val percentColor = if (isLoan) 0xFFF59E0B.toInt() else 0xFF6366F1.toInt()
            views.setTextColor(R.id.widget_percent, percentColor)
            views.setTextColor(
                R.id.widget_type_label,
                percentColor,
            )

            val uri = if (isLoan) {
                "budgetapp://open/loan/${item.id}"
            } else {
                "budgetapp://open/goal/${item.id}"
            }
            views.setOnClickPendingIntent(
                R.id.widget_progress,
                launchIntent(context, uri, appWidgetId),
            )
            views.setOnClickPendingIntent(
                R.id.widget_name,
                launchIntent(context, uri, appWidgetId + 1000),
            )
        }

        private fun bindPlaceholder(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
        ) {
            views.setTextViewText(R.id.widget_icon, "📊")
            views.setTextViewText(R.id.widget_name, context.getString(R.string.progress_widget_not_configured))
            views.setTextViewText(R.id.widget_type_label, "Progress")
            views.setTextViewText(R.id.widget_percent, "--")
            views.setTextViewText(R.id.widget_subtitle, "")
            views.setProgressBar(R.id.widget_progress, 100, 0, false)

            val configureIntent = Intent(context, ProgressWidgetConfigureActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val pending = PendingIntent.getActivity(
                context,
                appWidgetId,
                configureIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_name, pending)
        }

        private fun bindMissing(
            context: Context,
            views: RemoteViews,
            appWidgetId: Int,
        ) {
            views.setTextViewText(R.id.widget_icon, "⚠️")
            views.setTextViewText(
                R.id.widget_name,
                context.getString(R.string.progress_widget_missing_item),
            )
            views.setTextViewText(R.id.widget_type_label, "Progress")
            views.setTextViewText(R.id.widget_percent, "--")
            views.setTextViewText(R.id.widget_subtitle, "")
            views.setProgressBar(R.id.widget_progress, 100, 0, false)

            val configureIntent = Intent(context, ProgressWidgetConfigureActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val pending = PendingIntent.getActivity(
                context,
                appWidgetId + 2000,
                configureIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_name, pending)
        }

        private fun launchIntent(
            context: Context,
            uri: String,
            requestCode: Int,
        ): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse(uri)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        const val TYPE_GOAL = "goal"
        const val TYPE_LOAN = "loan"
    }
}
