import 'package:flutter/material.dart';
class PostNewJobSummary extends StatefulWidget {
	const PostNewJobSummary({super.key});
	@override
	PostNewJobSummaryState createState() => PostNewJobSummaryState();
}
class PostNewJobSummaryState extends State<PostNewJobSummary> {
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
										color: Color(0xFFF9F9F9),
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											padding: const EdgeInsets.only( bottom: 27),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 25),
															width: double.infinity,
															child: Stack(
																clipBehavior: Clip.none,
																children: [
																	Padding(
																		padding: const EdgeInsets.only( bottom: 31),
																		child: Column(
																			crossAxisAlignment: CrossAxisAlignment.start,
																			children: [
																				IntrinsicHeight(
																					child: Container(
																						color: Color(0xFF00AAA8),
																						padding: const EdgeInsets.only( top: 23),
																						width: double.infinity,
																						child: Column(
																							crossAxisAlignment: CrossAxisAlignment.start,
																							children: [
																								Container(
																									margin: const EdgeInsets.only( bottom: 15, left: 18),
																									width: 35,
																									height: 35,
																									child: Image.network(
																										"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/dPj38vYMjM/393xfml5_expires_30_days.png",
																										fit: BoxFit.fill,
																									)
																								),
																								Container(
																									margin: const EdgeInsets.only( bottom: 7, left: 29),
																									child: Text(
																										"Post new job",
																										style: TextStyle(
																											color: Color(0xFFFFFFFF),
																											fontSize: 16,
																											fontWeight: FontWeight.bold,
																										),
																									),
																								),
																								Container(
																									margin: const EdgeInsets.only( bottom: 57, left: 29),
																									child: Text(
																										"Summary",
																										style: TextStyle(
																											color: Color(0xFFFFFFFF),
																											fontSize: 12,
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
																	Positioned(
																		bottom: 0,
																		left: 29,
																		width: 33,
																		height: 8,
																		child: Text(
																			"Team",
																			style: TextStyle(
																				color: Color(0xFFB5B4B4),
																				fontSize: 12,
																			),
																		),
																	),
																]
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 16, left: 29),
														child: Text(
															"Title",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 22, left: 29),
														child: Text(
															"Create a logo for my company",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 12,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 14, left: 29),
														child: Text(
															"Description",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 29, left: 29, right: 44),
														width: double.infinity,
														child: Text(
															"I need a freelancer who experiences with logo design for my brand new company",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 12,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 13, left: 29),
														child: Text(
															"Total budget",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 23, left: 29),
														child: Text(
															"Rp. 6.000.000",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 12,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 14, left: 29),
														child: Text(
															"Working days",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 23, left: 30),
														child: Text(
															"30 days",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 12,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 16, left: 31),
														child: Text(
															"Deadline",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 28, left: 31),
														child: Text(
															"19 Mei 2023",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 12,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 13, left: 30),
														child: Text(
															"Payment type",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 26, left: 30),
														child: Text(
															"Milestone (25%, 75%, 100%)",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 12,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 20, left: 29),
														child: Text(
															"Roles",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 15, left: 29, right: 29),
															width: double.infinity,
															child: Row(
																mainAxisAlignment: MainAxisAlignment.spaceBetween,
																children: [
																	Text(
																		"UI Designer",
																		style: TextStyle(
																			color: Color(0xFFB5B4B4),
																			fontSize: 12,
																		),
																	),
																	Text(
																		"Rp. 1.500.000",
																		style: TextStyle(
																			color: Color(0xFFB5B4B4),
																			fontSize: 12,
																		),
																	),
																]
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 31, left: 30, right: 30),
															width: double.infinity,
															child: Row(
																mainAxisAlignment: MainAxisAlignment.spaceBetween,
																children: [
																	Text(
																		"Frontend web developer",
																		style: TextStyle(
																			color: Color(0xFFB5B4B4),
																			fontSize: 12,
																		),
																	),
																	Text(
																		"Rp. 4.500.000",
																		style: TextStyle(
																			color: Color(0xFFB5B4B4),
																			fontSize: 12,
																		),
																	),
																]
															),
														),
													),
													InkWell(
														onTap: () { print('Pressed'); },
														child: IntrinsicHeight(
															child: Container(
																decoration: BoxDecoration(
																	borderRadius: BorderRadius.circular(20),
																	color: Color(0xFF00AAA8),
																),
																padding: const EdgeInsets.symmetric(vertical: 13),
																margin: const EdgeInsets.symmetric(horizontal: 29),
																width: double.infinity,
																child: Column(
																	children: [
																		Text(
																			"Post new job",
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
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																borderRadius: BorderRadius.circular(20),
																color: Color(0xFFFAF9FE),
															),
															padding: const EdgeInsets.only( top: 32, left: 29),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Container(
																		margin: const EdgeInsets.only( bottom: 19),
																		child: Text(
																			"Type",
																			style: TextStyle(
																				color: Color(0xFF7D7D7D),
																				fontSize: 12,
																				fontWeight: FontWeight.bold,
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