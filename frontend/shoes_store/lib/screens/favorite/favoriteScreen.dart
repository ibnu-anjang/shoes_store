import 'package:flutter/material.dart';
import 'package:shoes_store/constant.dart';
import 'package:shoes_store/provider/favoriteProvider.dart';
import '../../widgets/smartImage.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = FavoriteProvider.of(context);
    final finalList = provider.favorites;
    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        backgroundColor: kcontentColor,
        title: const Text(
          "Favorite",
          style: TextStyle(
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: ListView.builder(
              itemCount:finalList.length,
              itemBuilder: (context, index){
                final favoritItem = finalList[index];
              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              color: kcontentColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: SmartImage(url: favoritItem.image),
                          ),
                          const SizedBox(width: 10,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                favoritItem.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 5,),
                              Text(
                                favoritItem.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8,),
                              Text(
                                formatRupiah(favoritItem.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    ),
                    Positioned(
                      top: 50,
                      right: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              provider.toggleFavorite(favoritItem);
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            ),
            ),
        ],
      ),
    );
  }
}