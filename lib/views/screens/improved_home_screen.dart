import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';
import '../../controllers/categorized_products_controller.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/products_controller.dart';
import '../widgets/all_products_section.dart';
import '../widgets/dynamic_sections_widget.dart';
import '../widgets/categories_section.dart';
import '../widgets/your_choice_section.dart';
import '../widgets/home_food_section.dart';
import '../widgets/offer_section.dart';
import '../widgets/welcome_section.dart';
import '../widgets/home_header.dart';
import '../widgets/categorized_products_section.dart';

class ImprovedHomeScreen extends StatelessWidget {
  const ImprovedHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomepageController>();

    // Instantiate lazy controllers OUTSIDE Obx to ensure onInit runs before the reactive build loop
    Get.find<CategorizedProductsController>();
    Get.find<ProductsController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
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
              SliverToBoxAdapter(child: YourChoiceSection()),
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
                Obx(
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
              Obx(
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
            SliverToBoxAdapter(child: YourChoiceSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: HomeFoodSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: DynamicSectionsWidget()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]);

          slivers.add(
            Obx(
              () => SliverMainAxisGroup(
                slivers: buildCategorizedProductsSection(context),
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

          slivers.add(
            Obx(
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
              final productsController = Get.find<ProductsController>();
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
