import 'package:flutter/material.dart';
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
											padding: const EdgeInsets.only( bottom: 210),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 19),
															width: double.infinity,
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
																											"https://storage.googleapis.com/tagjs-prod.appspot.com/v1/dPj38vYMjM/4mj25hfm_expires_30_days.png",
																											fit: BoxFit.fill,
																										)
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
																										margin: const EdgeInsets.only( bottom: 54, left: 29),
																										child: Text(
																											"Payment Detail",
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
																				borderRadius: BorderRadius.circular(20),
																				color: Color(0xFFFFFFFF),
																			),
																			padding: const EdgeInsets.symmetric(vertical: 3),
																			margin: const EdgeInsets.symmetric(horizontal: 29),
																			width: double.infinity,
																			child: Row(
																				children: [
																					Expanded(
																						child: Container(
																							width: double.infinity,
																							child: SizedBox(),
																						),
																					),
																					Text(
																						"Full",
																						style: TextStyle(
																							color: Color(0xFF7D7D7D),
																							fontSize: 12,
																						),
																					),
																					Expanded(
																						child: Container(
																							width: double.infinity,
																							child: SizedBox(),
																						),
																					),
																					InkWell(
																						onTap: () { print('Pressed'); },
																						child: IntrinsicWidth(
																							child: IntrinsicHeight(
																								child: Container(
																									decoration: BoxDecoration(
																										borderRadius: BorderRadius.circular(20),
																										color: Color(0xFF00AAA8),
																									),
																									padding: const EdgeInsets.only( top: 10, bottom: 10, left: 52, right: 52),
																									margin: const EdgeInsets.only( right: 2),
																									child: Column(
																										crossAxisAlignment: CrossAxisAlignment.start,
																										children: [
																											Text(
																												"Milestone",
																												style: TextStyle(
																													color: Color(0xFFFFFFFF),
																													fontSize: 12,
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
													Container(
														margin: const EdgeInsets.only( bottom: 31, left: 29),
														width: 309,
														child: Text(
															"Full payment, pay at the end of project finish\nMilestone payment, pay as their work progress, ex: 25%, 50%, 100%. (Usually for big and long term project)\n\nBetween full payment and milestone payment, you need to deposit your payment first before freelancer start to work your project.",
															style: TextStyle(
																color: Color(0xFFB5B4B4),
																fontSize: 10,
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 10, left: 32),
														child: Text(
															"Milestone",
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
															padding: const EdgeInsets.symmetric(vertical: 19),
															margin: const EdgeInsets.only( bottom: 25, left: 29, right: 29),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Container(
																		margin: const EdgeInsets.only( bottom: 12, left: 21),
																		child: Text(
																			"2 (50%, 100%)",
																			style: TextStyle(
																				color: Color(0xFF333333),
																				fontSize: 12,
																			),
																		),
																	),
																	Container(
																		margin: const EdgeInsets.only( bottom: 12, left: 21),
																		child: Text(
																			"3 (25%, 75%, 100%)",
																			style: TextStyle(
																				color: Color(0xFF333333),
																				fontSize: 12,
																			),
																		),
																	),
																	Container(
																		margin: const EdgeInsets.only( bottom: 12, left: 21),
																		child: Text(
																			"4 (25%, 50%, 75%, 100%)",
																			style: TextStyle(
																				color: Color(0xFF333333),
																				fontSize: 12,
																			),
																		),
																	),
																	Container(
																		margin: const EdgeInsets.only( left: 21),
																		child: Text(
																			"5 (15%, 30%, 50%, 75%, 100%)",
																			style: TextStyle(
																				color: Color(0xFF333333),
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
																margin: const EdgeInsets.symmetric(horizontal: 29),
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
															padding: const EdgeInsets.only( top: 41, left: 30),
															width: double.infinity,
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Container(
																		margin: const EdgeInsets.only( bottom: 10),
																		child: Text(
																			"Payment",
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