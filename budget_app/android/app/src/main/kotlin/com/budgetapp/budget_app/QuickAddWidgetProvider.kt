package com.budgetapp.budget_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class QuickAddWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)

            views.setOnClickPendingIntent(
                R.id.btn_add_income,
                launchIntent(context, INCOME_URI, 1),
            )
            views.setOnClickPendingIntent(
                R.id.btn_add_expense,
                launchIntent(context, EXPENSE_URI, 2),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
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

    companion object {
        private const val INCOME_URI = "budgetapp://add/income"
        private const val EXPENSE_URI = "budgetapp://add/expense"
    }
}
