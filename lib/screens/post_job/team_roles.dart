import 'package:flutter/material.dart';
import 'add_team.dart';
class PostNewJobTeamRoles extends StatefulWidget {
	const PostNewJobTeamRoles({super.key});
	@override
	PostNewJobTeamRolesState createState() => PostNewJobTeamRolesState();
}
class PostNewJobTeamRolesState extends State<PostNewJobTeamRoles> {
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
											padding: const EdgeInsets.only( bottom: 25),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															padding: const EdgeInsets.only( bottom: 29),
															margin: const EdgeInsets.only( bottom: 152),
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
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 25),
															width: double.infinity,
															child: Column(
																children: [
																	IntrinsicWidth(
																		child: IntrinsicHeight(
																			child: Container(
																				padding: const EdgeInsets.all(49),
																				decoration: BoxDecoration(
																					image: DecorationImage(
																						image: NetworkImage("https://storage.googleapis.com/tagjs-prod.appspot.com/v1/dPj38vYMjM/l2lzgmff_expires_30_days.png"),
																						fit: BoxFit.fill
																					),
																				),
																				child: Column(
																					crossAxisAlignment: CrossAxisAlignment.start,
																					children: [
																						Container(
																							color: Color(0xFFDCD8D8),
																							margin: const EdgeInsets.symmetric(vertical: 22),
																							width: 47,
																							height: 2,
																							child: SizedBox(),
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
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 198),
															width: double.infinity,
															child: Column(
																children: [
																	Text(
																		"Add team roles",
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
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.end,
																children: [
																	Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 26),
                                      child: FloatingActionButton(
                                        backgroundColor: Color(0xFF00AAA8),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const PostNewJobAddTeam(),
                                            ),
                                          );
                                        },
                                        child: Icon(Icons.add, color: Colors.white),
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