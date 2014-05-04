<?php
$page = $_SERVER['PHP_SELF'];
$sec = "3000000000";

/* Add project here to extend */
?>
<html>
	<head>
		<title>SNAP build dashboard</title>
		<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
		<link rel="stylesheet" href="css/main.css">
		<link rel="stylesheet" href="css/docs.min.css">
		<script src="//code.jquery.com/jquery-1.11.0.min.js"></script>
		<script src="//code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
		<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js"></script>

		<script type="text/javascript">
				// Refreshes frequently through an AJAX request.
				var currentBuildData;
				var currentActiveProject = null;

				// Maps the project key to the li element.
				var projectElementMap;

				var statusLabelMap = {
						"0" : "Successful",
						"-1" : "Queued",
						"1" : "Failed",
						"2" : "In Progress"
				};

				var statusClassMap = {
						"0" : "success",
						"-1" : "queued",
						"1" : "failed",
						"2" : "inprogress"
				};

				$(document).ready(function() {

					function refresh(data) {
						var dataContainer = $("#project-builds");
						var rows = data["rows"];
						var label = data["label"];
						
						// Clear the table except the first row (heading)
						while ($("#project-builds tr").length > 1) {
							$("#project-builds tr:last-child").remove();
						}
		
				
						for (var i=0; i < rows.length; i++) {
							var row = rows[i];
							var buildStatus = parseInt(row['build_status']);
							var testStatus = parseInt(row['test_status']);
							var trClass = getRowClass(buildStatus, testStatus);	

							dataContainer.append(
								$("<tr class='" + trClass + "' />").append(
									"<td>" + row["id"] +"</td>" + 
									"<td>" + row["tstart"] +"</td>" + 
									"<td>" + row["tend"] +"</td>" + 
									"<td class='" + statusClassMap[row['build_status']] + "'>" + statusLabelMap[row["build_status"]] +"</td>" + 
									"<td class='" + statusClassMap[row['test_status']] + "'>" + statusLabelMap[row["test_status"]] +"</td>" + 
									"<td><a target='_blank' href='logs/" + row["key"] + "/" + row["logs"] +"'>" + row["logs"] + "</a></td>"
								)
							);
						}

					}

					/*
						* Returns the cumulative status of the row based on build and test.
						* Current behaviour is to return failed if either test or build failed. 
						* 'progress' in case either is in progress.
						* 'success' if both build and test succeeded.
					 */
					function getRowClass(buildStatus, testStatus) {
						var trClass = "failed";
						if (buildStatus === -1 || buildStatus === 2 || testStatus === -1 || testStatus === 2) {
							trClass = "inprogress";	
						} else if (buildStatus === 0 && testStatus === 0) {
							trClass = "success";
						}
						return trClass;
					}

					/* 
					 * Returns the tab click handler. Necessary because JS has only function scope. 
					 * Anonmyous functions inside for-loops are trouble.
					 */
					function createTabHandler(projectName) {
						return function(e) {
							// Refresh the data in the table.
							refresh(currentBuildData[projectName]);

							// Change the current active project.
							var currentActiveTabSelector = "#" + currentActiveProject;
							$(currentActiveTabSelector).removeClass('active');
							currentActiveProject = projectName;

							currentActiveTabSelector = "#" + currentActiveProject;
							$(currentActiveTabSelector).addClass('active');
						}
					}

					function fetchAndRefreshData() {
						// Get status of all projects.
						$.ajax({
							url : "api/status.php",
							dataType : "json",
						})
						.done(function(response) {
							// Update currentBuildData.
							currentBuildData = response;
							var projectNames = [];

							// True only for the first request.
							if (currentActiveProject === null) {
								// Update the tabs with project names and attach handlers to click events.
								for(projectName in response) {
									projectNames.push(projectName);
									$("#project-tabs").append(
										$("<li id='" + projectName + "'/>").append(
											$("<a />")
												.attr("data-toggle", "tab")
												.html(response[projectName]["label"])
												.click(createTabHandler(projectName))
											)
										);
								}

								// Set the first tab as the active element and the first project as the currentActiveProject.
								var el = $("#project-tabs li:first");
								el.attr('class', 'active');
								currentActiveProject = projectNames[0];
							}

								// Create project summary for latest build and test status.
								// Clear the project summary div.
								$("#project-summary-container").empty();

								// For each project, add the the latest build summary to the project-summary-container div.
								for(projectName in response) {
									var latestBuildStatus = parseInt(response[projectName]["rows"][0]["build_status"])
									var latestTestStatus = parseInt(response[projectName]["rows"][0]["test_status"]);
									var label = response[projectName]["label"];

									$("<li />")
										.attr('class', 'project-summary ' + getRowClass(latestBuildStatus, latestTestStatus))
										.append("<h3>" + label + "</h3>")
										.append("<span>Build " + statusLabelMap[latestBuildStatus] + "</span>")
										.append("<span>Test  " + statusLabelMap[latestTestStatus] + "</span>")
										.appendTo("#project-summary-container");
								}
							refresh(response[currentActiveProject]);
						});
					}

					setInterval(fetchAndRefreshData, 30000);
					fetchAndRefreshData();
				});
		</script>
	</head>
	
	<body>
		<div class="container">
			<div class="header"><h3 class="text-muted">SNAP Build dashboard<h3></div>
				<ul id="project-summary-container" class="list-inline">
				</ul>

				<div id="project-builds-nav">
					<ul class="nav nav-tabs" id="project-tabs">
					</ul>

					<div id="project-builds-container">
						<table class="table" id="project-builds">
							<tr>
								<th>Build Number</th>
								<th>Start Time</th>
								<th>End Time</th>
								<th>Build Status</th>
								<th>Test Status</th>
								<th>Logs</th>
							</tr>
						</table>
					</div>
				</div>
			<div class="footer">&copy Stanford SNAP</div>
		</div>
	</body>
</html>
