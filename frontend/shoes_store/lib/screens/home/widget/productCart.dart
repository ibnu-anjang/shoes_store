import 'package:flutter/material.dart';
import 'package:shoes_store/models/productModel.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/favoriteProvider.dart';
import 'package:shoes_store/screens/detail/detailScreen.dart';
import '../../../widgets/smartImage.dart';


class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key , required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context, listen: true);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
           MaterialPageRoute(
            builder: (context) => DetailScreen(product: product,),
            ),
            );
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: kcontentColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 5,
                ),
                Center(
                  child: Hero(
                    tag: '${product.title}_${product.image}_${product.price}',
                    child: SmartImage(
                      url: product.image,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Padding(padding: const EdgeInsets.only(left: 10),
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ),
                const SizedBox(height: 10,),
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 8),
                  child: Text(
                    formatRupiah(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // fav icon
          Positioned(
            child: Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: kprimaryColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  provider.toggleFavorite(product);
                },
                child: Icon(
                  provider.isExist(product)?
                  Icons.favorite:
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    ),
  );
}
}