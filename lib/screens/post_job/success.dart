import 'package:flutter/material.dart';
class Frame1 extends StatefulWidget {
	const Frame1({super.key});
	@override
	Frame1State createState() => Frame1State();
}
class Frame1State extends State<Frame1> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: IntrinsicHeight(
									child: Container(
										color: Color(0xFFFFFFFF),
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															padding: const EdgeInsets.symmetric(vertical: 191),
															width: double.infinity,
															child: Column(
																children: [
																	Container(
																		margin: const EdgeInsets.only( bottom: 25),
																		width: 120,
																		height: 120,
																		child: Image.network(
																			"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/dPj38vYMjM/1nknw4lj_expires_30_days.png",
																			fit: BoxFit.fill,
																		)
																	),
																	Container(
																		margin: const EdgeInsets.only( bottom: 24),
																		width: 211,
																		child: Text(
																			"Yeaayy. \nYour job has been posted!",
																			style: TextStyle(
																				color: Color(0xFF00AAA8),
																				fontSize: 16,
																				fontWeight: FontWeight.bold,
																			),
																			textAlign: TextAlign.center,
																		),
																	),
																	Container(
																		margin: const EdgeInsets.only( bottom: 25, left: 37, right: 37),
																		width: double.infinity,
																		child: Text(
																			"Your post will be review. If your post has been approved, it will be automatically on list job can can view by public.",
																			style: TextStyle(
																				color: Color(0xFF7D7D7D),
																				fontSize: 12,
																			),
																			textAlign: TextAlign.center,
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.symmetric(horizontal: 38),
																			width: double.infinity,
																			child: Row(
																				children: [
																					Expanded(
																						child: InkWell(
																							onTap: () { print('Pressed'); },
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(20),
																										color: Color(0xFF00AAA8),
																									),
																									padding: const EdgeInsets.symmetric(vertical: 13),
																									margin: const EdgeInsets.only( right: 14),
																									width: double.infinity,
																									child: Column(
																										children: [
																											Text(
																												"View job",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 12,
																													fontWeight: FontWeight.bold,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					),
																					Expanded(
																						child: InkWell(
																							onTap: () { print('Pressed'); },
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(20),
																										color: Color(0xFF00AAA8),
																									),
																									padding: const EdgeInsets.symmetric(vertical: 13),
																									width: double.infinity,
																									child: Column(
																										children: [
																											Text(
																												"Post  other job",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 12,
																													fontWeight: FontWeight.bold,
																												),
																											),
																										]
																									),
																								),
																							),
																						),
																					),
																				]
																			),
																		),
																	),
																]
															),
														),
													),
												],
											)
										),
									),
								),
							),
						],
					),
				),
			),
		);
	}
}