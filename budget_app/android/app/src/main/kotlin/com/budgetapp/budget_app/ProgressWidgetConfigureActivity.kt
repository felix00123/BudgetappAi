package com.budgetapp.budget_app

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView

class ProgressWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.progress_widget_configure)

        val goals = WidgetSnapshotHelper.readGoals(this)
        val loans = WidgetSnapshotHelper.readLoans(this)
        val emptyMessage = findViewById<TextView>(R.id.empty_message)
        val goalsList = findViewById<ListView>(R.id.goals_list)
        val loansList = findViewById<ListView>(R.id.loans_list)

        if (goals.isEmpty() && loans.isEmpty()) {
            emptyMessage.visibility = View.VISIBLE
            goalsList.visibility = View.GONE
            loansList.visibility = View.GONE
            return
        }

        emptyMessage.visibility = View.GONE

        if (goals.isEmpty()) {
            goalsList.visibility = View.GONE
        } else {
            goalsList.adapter = ArrayAdapter(
                this,
                android.R.layout.simple_list_item_1,
                goals.map { "${it.icon} ${it.name} — ${it.progress}%" },
            )
            goalsList.onItemClickListener = AdapterView.OnItemClickListener { _, _, position, _ ->
                val item = goals[position]
                finishConfiguration(
                    ProgressWidgetProvider.TYPE_GOAL,
                    item,
                )
            }
        }

        if (loans.isEmpty()) {
            loansList.visibility = View.GONE
        } else {
            loansList.adapter = ArrayAdapter(
                this,
                android.R.layout.simple_list_item_1,
                loans.map { "${it.icon} ${it.name} — ${it.progress}%" },
            )
            loansList.onItemClickListener = AdapterView.OnItemClickListener { _, _, position, _ ->
                val item = loans[position]
                finishConfiguration(
                    ProgressWidgetProvider.TYPE_LOAN,
                    item,
                )
            }
        }
    }

    private fun finishConfiguration(type: String, item: WidgetProgressItem) {
        ProgressWidgetConfigStore.save(
            context = this,
            appWidgetId = appWidgetId,
            type = type,
            itemId = item.id,
            name = item.name,
            icon = item.icon,
        )

        val manager = AppWidgetManager.getInstance(this)
        ProgressWidgetProvider.updateAppWidget(this, manager, appWidgetId)

        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
}
