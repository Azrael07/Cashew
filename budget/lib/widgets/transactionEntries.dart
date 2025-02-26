import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/pastBudgetsPage.dart';
import 'package:budget/pages/transactionsSearchPage.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/dateDivider.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/transactionEntry/transactionEntry.dart';
import 'package:flutter/material.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/ghostTransactions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:googleapis/analyticsreporting/v4.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:provider/provider.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'dart:math';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/randomConstants.dart';

class TransactionEntries extends StatelessWidget {
  const TransactionEntries(
    this.startDay,
    this.endDay, {
    this.search = "",
    this.categoryFks,
    this.categoryFksExclude,
    this.walletFks = const [],
    this.onSelected,
    this.listID,
    this.income,
    this.renderAsSlivers = true,
    this.budgetTransactionFilters,
    this.memberTransactionFilters,
    this.member,
    this.onlyShowTransactionsBelongingToBudgetPk,
    this.onlyShowTransactionsBelongingToObjectivePk,
    this.simpleListRender = false,
    this.budget,
    this.dateDividerColor,
    this.transactionBackgroundColor,
    this.categoryTintColor,
    this.useHorizontalPaddingConstrained = true,
    this.limit,
    this.showNoResults = true,
    this.colorScheme,
    this.noSearchResultsVariation = false,
    this.noResultsMessage,
    this.searchFilters,
    this.pastDaysLimitToShow,
    this.includeDateDivider = true,
    this.allowSelect = true,
    this.showObjectivePercentage = true,
    this.noResultsPadding,
    this.noResultsExtraWidget,
    this.limitPerDay,
    super.key,
  });
  final DateTime? startDay;
  final DateTime? endDay;
  final String search;
  final List<String>? categoryFks;
  final List<String>? categoryFksExclude;
  final List<String> walletFks;
  final Function(Transaction, bool)? onSelected;
  final String? listID;
  final bool? income;
  final bool renderAsSlivers;
  final List<BudgetTransactionFilters>? budgetTransactionFilters;
  final List<String>? memberTransactionFilters;
  final String? member;
  final String? onlyShowTransactionsBelongingToBudgetPk;
  final String? onlyShowTransactionsBelongingToObjectivePk;
  final bool simpleListRender;
  final Budget? budget;
  final Color? dateDividerColor;
  final Color? transactionBackgroundColor;
  final Color? categoryTintColor;
  final bool useHorizontalPaddingConstrained;
  final int? limit;
  final bool showNoResults;
  final ColorScheme? colorScheme;
  final bool noSearchResultsVariation;
  final String? noResultsMessage;
  final SearchFilters? searchFilters;
  final int? pastDaysLimitToShow;
  final bool includeDateDivider;
  final bool allowSelect;
  final bool showObjectivePercentage;
  final EdgeInsets? noResultsPadding;
  final Widget? noResultsExtraWidget;
  final int? limitPerDay;

  Widget createTransactionEntry(
      List<TransactionWithCategory> transactionListForDay,
      TransactionWithCategory item,
      int index) {
    return TransactionEntry(
      transactionBefore:
          nullIfIndexOutOfRange(transactionListForDay, index - 1)?.transaction,
      transactionAfter:
          nullIfIndexOutOfRange(transactionListForDay, index + 1)?.transaction,
      categoryTintColor: categoryTintColor,
      useHorizontalPaddingConstrained: useHorizontalPaddingConstrained,
      containerColor: transactionBackgroundColor,
      key: ValueKey(item.transaction.transactionPk),
      category: item.category,
      subCategory: item.subCategory,
      budget: item.budget,
      objective: item.objective,
      openPage: AddTransactionPage(
        transaction: item.transaction,
        routesToPopAfterDelete: RoutesToPopAfterDelete.One,
      ),
      transaction: item.transaction,
      onSelected: (Transaction transaction, bool selected) {
        onSelected?.call(transaction, selected);
      },
      listID: listID,
      allowSelect: allowSelect,
      showObjectivePercentage: showObjectivePercentage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionWithCategory>>(
      stream: database.getTransactionCategoryWithDay(
        startDay,
        endDay,
        search: search,
        categoryFks: categoryFks,
        categoryFksExclude: categoryFksExclude,
        walletFks: walletFks,
        income: income,
        budgetTransactionFilters: budgetTransactionFilters,
        memberTransactionFilters: memberTransactionFilters,
        member: member,
        onlyShowTransactionsBelongingToBudgetPk:
            onlyShowTransactionsBelongingToBudgetPk,
        onlyShowTransactionsBelongingToObjectivePk:
            onlyShowTransactionsBelongingToObjectivePk,
        searchFilters: searchFilters,
        limit: limit,
        budget: budget,
      ),
      builder: (context, snapshot) {
        if (snapshot.data != null && snapshot.hasData) {
          if (snapshot.data!.length > 0) {
            List<Widget> widgetsOut = [];
            int currentTotalIndex = 0;

            List<TransactionWithCategory> transactionListForDay = [];
            double totalSpentForDay = 0;
            DateTime? currentDate;
            int totalUniqueDays = 0;

            for (TransactionWithCategory transactionWithCategory
                in snapshot.data ?? []) {
              if (pastDaysLimitToShow != null &&
                  totalUniqueDays > pastDaysLimitToShow!) break;

              DateTime currentTransactionDate = DateTime(
                  transactionWithCategory.transaction.dateCreated.year,
                  transactionWithCategory.transaction.dateCreated.month,
                  transactionWithCategory.transaction.dateCreated.day);
              if (currentDate == null) {
                currentDate = currentTransactionDate;
                totalUniqueDays++;
              }
              if (currentDate == currentTransactionDate) {
                transactionListForDay.add(transactionWithCategory);
                if (transactionWithCategory.transaction.paid)
                  totalSpentForDay += transactionWithCategory
                          .transaction.amount *
                      (amountRatioToPrimaryCurrencyGivenPk(
                              Provider.of<AllWallets>(context),
                              transactionWithCategory.transaction.walletFk) ??
                          0);
              }

              DateTime? nextTransactionDate =
                  (snapshot.data ?? []).length == currentTotalIndex + 1
                      ? null
                      : DateTime(
                          (snapshot.data ?? [])[currentTotalIndex + 1]
                              .transaction
                              .dateCreated
                              .year,
                          (snapshot.data ?? [])[currentTotalIndex + 1]
                              .transaction
                              .dateCreated
                              .month,
                          (snapshot.data ?? [])[currentTotalIndex + 1]
                              .transaction
                              .dateCreated
                              .day,
                        );

              if (nextTransactionDate == null ||
                  nextTransactionDate != currentTransactionDate) {
                if (transactionListForDay.length > 0) {
                  Widget dateDividerWidget = includeDateDivider == false
                      ? SizedBox.shrink()
                      : DateDivider(
                          useHorizontalPaddingConstrained:
                              useHorizontalPaddingConstrained,
                          color: dateDividerColor,
                          date: currentTransactionDate,
                          info: transactionListForDay.length > 1
                              ? convertToMoney(Provider.of<AllWallets>(context),
                                  totalSpentForDay)
                              : "");
                  if (renderAsSlivers) {
                    List<TransactionWithCategory> transactionListForDayCopy = [
                      ...transactionListForDay
                    ];
                    Widget sliverList = simpleListRender
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: transactionListForDayCopy.length,
                              (BuildContext context, int index) {
                                TransactionWithCategory item =
                                    transactionListForDayCopy[index];
                                return createTransactionEntry(
                                    transactionListForDayCopy, item, index);
                              },
                            ),
                          )
                        : SliverImplicitlyAnimatedList<TransactionWithCategory>(
                            items: transactionListForDay,
                            areItemsTheSame: (a, b) =>
                                a.transaction.transactionPk ==
                                b.transaction.transactionPk,
                            insertDuration: Duration(milliseconds: 500),
                            removeDuration: Duration(milliseconds: 500),
                            updateDuration: Duration(milliseconds: 500),
                            itemBuilder: (BuildContext context,
                                Animation<double> animation,
                                TransactionWithCategory item,
                                int index) {
                              return SizeFadeTransition(
                                sizeFraction: 0.7,
                                curve: Curves.easeInOut,
                                animation: animation,
                                child: createTransactionEntry(
                                    transactionListForDayCopy, item, index),
                              );
                            },
                          );
                    widgetsOut.add(
                      SliverStickyHeader(
                        header: Transform.translate(
                            offset: Offset(0, -1),
                            child: transactionListForDay.length > 0
                                ? includeDateDivider == false
                                    ? SizedBox.shrink()
                                    : dateDividerWidget
                                : SizedBox.shrink()),
                        sticky: true,
                        sliver: sliverList,
                      ),
                    );
                  } else {
                    // Render as non slivers
                    widgetsOut.add(dateDividerWidget);
                    for (int i = 0; i < transactionListForDay.length; i++) {
                      TransactionWithCategory item = transactionListForDay[i];
                      widgetsOut.add(createTransactionEntry(
                          transactionListForDay, item, i));
                    }
                  }

                  currentDate = null;
                  transactionListForDay = [];
                  totalSpentForDay = 0;
                }
              }
              currentTotalIndex++;
            }
            if (renderAsSlivers) {
              return MultiSliver(children: widgetsOut);
            } else {
              return ListView(
                scrollDirection: Axis.vertical,
                children: widgetsOut,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
              );
            }
          }
        } else {
          print(random.nextInt(100));
          Widget ghostTransactions = Column(
            children: [
              for (int i = 0; i < 5 + random.nextInt(5); i++)
                GhostTransactions(
                  i: random.nextInt(100),
                  useHorizontalPaddingConstrained: true,
                ),
            ],
          );
          if (renderAsSlivers) {
            return SliverToBoxAdapter(child: ghostTransactions);
          } else {
            return ghostTransactions;
          }
        }

        Widget noResults = Column(
          children: [
            NoResults(
              message: noResultsMessage ??
                  "no-transactions-within-time-range".tr() +
                      "." +
                      (budget != null
                          ? ("\n" +
                              "(" +
                              getWordedDateShortMore(
                                  startDay ?? DateTime.now()) +
                              " - " +
                              getWordedDateShortMore(endDay ?? DateTime.now()) +
                              ")")
                          : ""),
              tintColor: colorScheme != null
                  ? colorScheme?.primary.withOpacity(0.6)
                  : null,
              noSearchResultsVariation: noSearchResultsVariation,
              padding: noResultsPadding,
            ),
            if (noResultsExtraWidget != null) noResultsExtraWidget!,
          ],
        );
        if (renderAsSlivers) {
          return SliverToBoxAdapter(child: noResults);
        } else {
          return noResults;
        }
      },
    );
  }
}
