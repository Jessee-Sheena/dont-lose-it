import 'package:flutter/material.dart';
import 'package:keep_stuff/const.dart';

// this item is the tile that is dynamically built in the list view builder.
class ItemListTile extends StatelessWidget {
  final Widget image;
  final Widget itemName;
  final Widget itemLocation;
  final Function onTap;
  const ItemListTile(
      {this.image, this.itemName, this.itemLocation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 25, top: 25, right: 25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: kBlueColor,
      ),
      child: GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              image == null ? SizedBox() : image,
              itemName,
              itemLocation,
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
