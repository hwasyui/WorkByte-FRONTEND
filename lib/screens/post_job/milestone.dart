import 'package:flutter/material.dart';
class PostNewJobMilestone extends StatefulWidget {
	const PostNewJobMilestone({super.key});
	@override
	PostNewJobMilestoneState createState() => PostNewJobMilestoneState();
}
class PostNewJobMilestoneState extends State<PostNewJobMilestone> {
	String textField1 = '';
	String textField2 = '';
	String textField3 = '';
	String textField4 = '';
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
											padding: const EdgeInsets.only( bottom: 284),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 27),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 25),
																			width: double.infinity,
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
																											"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/dPj38vYMjM/l3o7fcoh_expires_30_days.png",
																											fit: BoxFit.fill,
																										)
																									),
																									Container(
																										margin: const EdgeInsets.only( bottom: 6, left: 29),
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
																										margin: const EdgeInsets.only( bottom: 60, left: 29),
																										child: Text(
																											"Milestone",
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
																	),
																	IntrinsicHeight(
																		child: Container(
																			decoration: BoxDecoration(
																				border: Border.all(
																					color: Color(0xFFF0F0F1),
																					width: 1,
																				),
																				borderRadius: BorderRadius.circular(10),
																				color: Color(0xFFFFFFFF),
																			),
																			padding: const EdgeInsets.symmetric(vertical: 16),
																			margin: const EdgeInsets.symmetric(horizontal: 26),
																			width: double.infinity,
																			child: Column(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.only( bottom: 6, left: 20, right: 33),
																							width: double.infinity,
																							child: Row(
																								mainAxisAlignment: MainAxisAlignment.spaceBetween,
																								children: [
																									Text(
																										"Work progress",
																										style: TextStyle(
																											color: Color(0xFF7D7D7D),
																											fontSize: 12,
																											fontWeight: FontWeight.bold,
																										),
																									),
																									Text(
																										"Payment Percentage",
																										style: TextStyle(
																											color: Color(0xFF7D7D7D),
																											fontSize: 12,
																											fontWeight: FontWeight.bold,
																										),
																									),
																								]
																							),
																						),
																					),
																					IntrinsicHeight(
																						child: Container(
																							margin: const EdgeInsets.symmetric(horizontal: 20),
																							width: double.infinity,
																							child: Row(
																								children: [
																									Expanded(
																										child: IntrinsicHeight(
																											child: Container(
																												alignment: Alignment.center,
																												decoration: BoxDecoration(
																													border: Border.all(
																														color: Color(0xFFF0F0F1),
																														width: 1,
																													),
																													borderRadius: BorderRadius.circular(10),
																													color: Color(0xFFFFFFFF),
																												),
																												margin: const EdgeInsets.only( right: 19),
																												width: double.infinity,
																												child: TextField(
																													style: TextStyle(
																														color: Color(0xFFB5B4B4),
																														fontSize: 12,
																													),
																													onChanged: (value) { 
																														setState(() { textField1 = value; });
																													},
																													decoration: InputDecoration(
																														hintText: "Ex: 25%",
																														isDense: true,
																														contentPadding: const EdgeInsets.only( top: 22, bottom: 22, left: 17, right: 17),
																														border: InputBorder.none,
																														focusedBorder: InputBorder.none,
																														filled: false,
																													),
																												),
																											),
																										),
																									),
																									Expanded(
																										child: IntrinsicHeight(
																											child: Container(
																												alignment: Alignment.center,
																												decoration: BoxDecoration(
																													border: Border.all(
																														color: Color(0xFFF0F0F1),
																														width: 1,
																													),
																													borderRadius: BorderRadius.circular(10),
																													color: Color(0xFFFFFFFF),
																												),
																												width: double.infinity,
																												child: TextField(
																													style: TextStyle(
																														color: Color(0xFFB5B4B4),
																														fontSize: 12,
																													),
																													onChanged: (value) { 
																														setState(() { textField2 = value; });
																													},
																													decoration: InputDecoration(
																														hintText: "Ex: 25%",
																														isDense: true,
																														contentPadding: const EdgeInsets.only( top: 22, bottom: 22, left: 19, right: 19),
																														border: InputBorder.none,
																														focusedBorder: InputBorder.none,
																														filled: false,
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
																]
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 11, left: 28),
														child: Text(
															"Milestone 2",
															style: TextStyle(
																color: Color(0xFF7D7D7D),
																fontSize: 12,
																fontWeight: FontWeight.bold,
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																border: Border.all(
																	color: Color(0xFFF0F0F1),
																	width: 1,
																),
																borderRadius: BorderRadius.circular(10),
																color: Color(0xFFFFFFFF),
															),
															padding: const EdgeInsets.symmetric(vertical: 18),
															margin: const EdgeInsets.only( bottom: 24, left: 26, right: 26),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.only( bottom: 6, left: 20, right: 33),
																			width: double.infinity,
																			child: Row(
																				mainAxisAlignment: MainAxisAlignment.spaceBetween,
																				children: [
																					Text(
																						"Work progress",
																						style: TextStyle(
																							color: Color(0xFF7D7D7D),
																							fontSize: 12,
																							fontWeight: FontWeight.bold,
																						),
																					),
																					Text(
																						"Payment Percentage",
																						style: TextStyle(
																							color: Color(0xFF7D7D7D),
																							fontSize: 12,
																							fontWeight: FontWeight.bold,
																						),
																					),
																				]
																			),
																		),
																	),
																	IntrinsicHeight(
																		child: Container(
																			margin: const EdgeInsets.symmetric(horizontal: 20),
																			width: double.infinity,
																			child: Row(
																				children: [
																					Expanded(
																						child: IntrinsicHeight(
																							child: Container(
																								alignment: Alignment.center,
																								decoration: BoxDecoration(
																									border: Border.all(
																										color: Color(0xFFF0F0F1),
																										width: 1,
																									),
																									borderRadius: BorderRadius.circular(10),
																									color: Color(0xFFFFFFFF),
																								),
																								margin: const EdgeInsets.only( right: 19),
																								width: double.infinity,
																								child: TextField(
																									style: TextStyle(
																										color: Color(0xFFB5B4B4),
																										fontSize: 12,
																									),
																									onChanged: (value) { 
																										setState(() { textField3 = value; });
																									},
																									decoration: InputDecoration(
																										hintText: "Ex: 50%",
																										isDense: true,
																										contentPadding: const EdgeInsets.only( top: 22, bottom: 22, left: 17, right: 17),
																										border: InputBorder.none,
																										focusedBorder: InputBorder.none,
																										filled: false,
																									),
																								),
																							),
																						),
																					),
																					Expanded(
																						child: IntrinsicHeight(
																							child: Container(
																								alignment: Alignment.center,
																								decoration: BoxDecoration(
																									border: Border.all(
																										color: Color(0xFFF0F0F1),
																										width: 1,
																									),
																									borderRadius: BorderRadius.circular(10),
																									color: Color(0xFFFFFFFF),
																								),
																								width: double.infinity,
																								child: TextField(
																									style: TextStyle(
																										color: Color(0xFFB5B4B4),
																										fontSize: 12,
																									),
																									onChanged: (value) { 
																										setState(() { textField4 = value; });
																									},
																									decoration: InputDecoration(
																										hintText: "Ex: 50%",
																										isDense: true,
																										contentPadding: const EdgeInsets.only( top: 22, bottom: 22, left: 19, right: 19),
																										border: InputBorder.none,
																										focusedBorder: InputBorder.none,
																										filled: false,
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
													InkWell(
														onTap: () { print('Pressed'); },
														child: IntrinsicHeight(
															child: Container(
																decoration: BoxDecoration(
																	borderRadius: BorderRadius.circular(20),
																	color: Color(0xFF00AAA8),
																),
																padding: const EdgeInsets.symmetric(vertical: 15),
																margin: const EdgeInsets.symmetric(horizontal: 27),
																width: double.infinity,
																child: Column(
																	children: [
																		Text(
																			"Next",
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
															padding: const EdgeInsets.only( top: 38, left: 28),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Container(
																		margin: const EdgeInsets.only( bottom: 15),
																		child: Text(
																			"Milestone 1",
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