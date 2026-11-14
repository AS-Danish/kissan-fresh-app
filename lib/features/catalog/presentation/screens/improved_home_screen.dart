import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissanfresh/features/catalog/application/categorized_products_controller.dart';
import 'package:kissanfresh/features/catalog/application/homepage_controller.dart';
import 'package:kissanfresh/features/catalog/application/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:kissanfresh/core/observable.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/all_products_section.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/dynamic_sections_widget.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/categories_section.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/your_choice_section.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/home_food_section.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/offer_section.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/welcome_section.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/home_header.dart';
import 'package:kissanfresh/features/catalog/presentation/widgets/categorized_products_section.dart';

class ImprovedHomeScreen extends StatelessWidget {
  const ImprovedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(homepageControllerProvider);

    // Instantiate lazy controllers OUTSIDE FieldBuilder to ensure onInit runs before the reactive build loop
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(categorizedProductsControllerProvider);
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(productsControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FieldBuilder(() {
        List<Widget> slivers = [
          SliverToBoxAdapter(child: HomeHeader()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ];

        if (controller.currentTab.value == 'Grocery') {
          if (controller.categories.isEmpty) {
            slivers.add(
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          } else {
            final int selectedIdx = controller.selectedIndex.value;
            final bool isValidIndex =
                selectedIdx >= 0 && selectedIdx < controller.categories.length;
            final isAll =
                isValidIndex &&
                controller.categories[selectedIdx].label == 'All';

            slivers.addAll([
              SliverToBoxAdapter(
                child: CategoriesSection(
                  categories: controller.categories,
                  selectedIndex: controller.selectedIndex.value,
                  onCategorySelected: controller.selectCategory,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              SliverToBoxAdapter(child: const YourChoiceSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ]);

            if (isAll) {
              slivers.addAll([
                SliverToBoxAdapter(child: WelcomeSection()),
                SliverToBoxAdapter(child: OffersSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
                SliverToBoxAdapter(child: DynamicSectionsWidget()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ]);

              slivers.add(
                FieldBuilder(
                  () => SliverMainAxisGroup(
                    slivers: buildCategorizedProductsSection(context),
                  ),
                ),
              );
              slivers.add(
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              );
            }

            slivers.add(
              FieldBuilder(
                () => SliverMainAxisGroup(
                  slivers: buildAllProductsSection(context),
                ),
              ),
            );
            slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));
          }
        } else {
          slivers.addAll([
            SliverToBoxAdapter(
              child: CategoriesSection(
                categories: controller.homeFoodCategories,
                selectedIndex: controller.selectedHomeFoodIndex.value,
                onCategorySelected: controller.selectHomeFoodCategory,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: const YourChoiceSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: HomeFoodSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: DynamicSectionsWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]);

          slivers.add(
            FieldBuilder(
              () => SliverMainAxisGroup(
                slivers: buildCategorizedProductsSection(context),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

          slivers.add(
            FieldBuilder(
              () => SliverMainAxisGroup(
                slivers: buildAllProductsSection(context),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 500) {
              final productsController = ProviderScope.containerOf(
                context,
                listen: false,
              ).read(productsControllerProvider);
              if (!productsController.isFetchingMore.value &&
                  productsController.hasMoreProducts.value) {
                productsController.fetchNextPage();
              }
            }
            return false;
          },
          child: CustomScrollView(
            scrollCacheExtent: const ScrollCacheExtent.pixels(300),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: slivers,
          ),
        );
      }),
    );
  }
}
