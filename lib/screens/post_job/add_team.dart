import 'package:flutter/material.dart';
class PostNewJobAddTeam extends StatefulWidget {
	const PostNewJobAddTeam({super.key});
	@override
	PostNewJobAddTeamState createState() => PostNewJobAddTeamState();
}
class PostNewJobAddTeamState extends State<PostNewJobAddTeam> {
	String textField1 = '';
	String textField2 = '';
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
											padding: const EdgeInsets.only( bottom: 201),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															width: double.infinity,
															child: Stack(
																clipBehavior: Clip.none,
																children: [
																	Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(25),
																						color: Color(0x99000000),
																					),
																					padding: const EdgeInsets.only( bottom: 404),
																					width: double.infinity,
																					child: Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							IntrinsicHeight(
																								child: Container(
																									padding: const EdgeInsets.only( bottom: 29),
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
																															InkWell(
                                                                onTap: () {
                                                                  Navigator.pop(context);
                                                                },
                                                                child: Container(
                                                                  margin: const EdgeInsets.only(bottom: 15, left: 18),
                                                                  child: Icon(
                                                                    Icons.arrow_back,
                                                                    color: Colors.white,
                                                                    size: 28,
                                                                  ),
                                                                ),
                                                              ),

																															Container(
																																margin: const EdgeInsets.only( bottom: 9, left: 29),
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
																																	"Team Roles ",
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
																						]
																					),
																				),
																			),
																		]
																	),
																	Positioned(
																		bottom: 0,
																		left: 0,
																		right: 0,
																		child: IntrinsicHeight(
																			child: Container(
																				decoration: BoxDecoration(
																					borderRadius: BorderRadius.circular(25),
																					color: Color(0xFFF9F9F9),
																				),
																				padding: const EdgeInsets.symmetric(vertical: 17),
																				transform: Matrix4.translationValues(0, 201, 0),
																				width: double.infinity,
																				child: Column(
																					crossAxisAlignment: CrossAxisAlignment.start,
																					children: [
																						IntrinsicHeight(
																							child: Container(
																								margin: const EdgeInsets.only( bottom: 27),
																								width: double.infinity,
																								child: Column(
																									children: [
																										Container(
																											color: Color(0xFFDCD8D8),
																											width: 170,
																											height: 4,
																											child: SizedBox(),
																										),
																									]
																								),
																							),
																						),
																						Container(
																							margin: const EdgeInsets.only( bottom: 10, left: 29),
																							child: Text(
																								"Role",
																								style: TextStyle(
																									color: Color(0xFF7D7D7D),
																									fontSize: 12,
																									fontWeight: FontWeight.bold,
																								),
																							),
																						),
																						IntrinsicHeight(
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
																								margin: const EdgeInsets.only( bottom: 19, left: 26, right: 26),
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
																										hintText: "Ex: UI Designer",
																										isDense: true,
																										contentPadding: const EdgeInsets.only( top: 20, bottom: 20, left: 19, right: 19),
																										border: InputBorder.none,
																										focusedBorder: InputBorder.none,
																										filled: false,
																									),
																								),
																							),
																						),
																						Container(
																							margin: const EdgeInsets.only( bottom: 6, left: 29),
																							child: Text(
																								"Budget",
																								style: TextStyle(
																									color: Color(0xFF7D7D7D),
																									fontSize: 12,
																									fontWeight: FontWeight.bold,
																								),
																							),
																						),
																						IntrinsicHeight(
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
																								margin: const EdgeInsets.only( bottom: 23, left: 26, right: 26),
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
																										hintText: "Ex: Rp. 1.000.000",
																										isDense: true,
																										contentPadding: const EdgeInsets.only( top: 21, bottom: 21, left: 19, right: 19),
																										border: InputBorder.none,
																										focusedBorder: InputBorder.none,
																										filled: false,
																									),
																								),
																							),
																						),
																						Container(
																							margin: const EdgeInsets.only( bottom: 7, left: 30),
																							child: Text(
																								"Description",
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
																								padding: const EdgeInsets.only( top: 22),
																								margin: const EdgeInsets.only( bottom: 27, left: 27, right: 27),
																								width: double.infinity,
																								child: Column(
																									children: [
																										Container(
																											margin: const EdgeInsets.only( bottom: 114),
																											child: Text(
																												"Ex: We need UI Designer who can work with team",
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
																						InkWell(
																							onTap: () { print('Pressed'); },
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(20),
																										color: Color(0xFF00AAA8),
																									),
																									padding: const EdgeInsets.symmetric(vertical: 15),
																									margin: const EdgeInsets.symmetric(horizontal: 30),
																									width: double.infinity,
																									child: Column(
																										children: [
																											Text(
																												"Add",
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
																					]
																				),
																			),
																		),
																	),
																]
															),
														),
													),
													Container(
														decoration: BoxDecoration(
															borderRadius: BorderRadius.circular(20),
															color: Color(0xFFFAF9FE),
														),
														height: 63,
														width: double.infinity,
														child: SizedBox(),
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