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
				var currentActiveTab = null;
				// Refreshes frequently through an AJAX request.
				var currentBuildData;

				var buildStatusLabel = {
						"0" : "Successful",
						"-1" : "Queued",
						"1" : "Failed",
						"2" : "In Progress"
				};

				var buildStatusClass = {
						"0" : "success",
						"-1" : "queued",
						"1" : "failed",
						"2" : "progress"
				};

				$(document).ready(function() {
					function refresh(data) {
						var dataContainer = $("#project-builds");
						
						// Clear the table except the first row (heading)
						while ($("#project-builds tr").length > 1) {
							$("#project-builds tr:last-child").remove();
						}
				
						for (var i=0; i<data.length; i++) {
							var row = data[i];
							var buildStatus = parseInt(row['build_status']);
							var testStatus = parseInt(row['test_status']);
							var trClass = "failed";

							if (buildStatus === -1 || buildStatus === 2 || testStatus === -1 || testStatus === 2) {
								trClass = "progress";	
							} else if (buildStatus === 0 && testStatus === 0) {
								trClass = "success";
							}

							dataContainer.append(
								$("<tr class='" + trClass + "' />").append(
									"<td>" + row["id"] +"</td>" + 
									"<td>" + row["tstart"] +"</td>" + 
									"<td>" + row["tend"] +"</td>" + 
									"<td class='" + buildStatusClass[row['build_status']] + "'>" + buildStatusLabel[row["build_status"]] +"</td>" + 
									"<td class='" + buildStatusClass[row['test_status']] + "'>" + buildStatusLabel[row["test_status"]] +"</td>" + 
									"<td><a target='_blank' href='logs/" + row["key"] + "/" + row["logs"] +"'>" + row["logs"] + "</a></td>"
								)
							);
						}
					}

					/* 
						* Returns the tab click handler. Necessary because JS has only function scope. 
						* Anonmyous functions inside for loops are trouble.
					 */
					function createTabHandler(label) {
						return function(e) {
							// Refresh the data in the table.
							refresh(currentBuildData[label]);
							$(currentActiveTab).removeClass('active');
							currentActiveTab = $(e.target).parent();
							$(currentActiveTab).addClass('active');
						}
					}

					// Get status of all projects.
					$.ajax({
						url : "api/status.php",
						dataType : "json",
					})
					.done(function(response) {
						// Update currentBuildData.
						currentBuildData = response;
						var labelArray = [];

						// true only for the first request.
						if (currentActiveTab === null) {
							for(label in response) {
								labelArray.push(label);
								$("#project-tabs").append(
									$("<li />").append(
										$("<a />")
											.attr("data-toggle", "tab")
											.html(label)
											.click(createTabHandler(label))
										)
								);
							}
							var el = $("#project-tabs li:first");
							el.attr('class', 'active');
							currentActiveTab = el;
							refresh(response[labelArray[0]]);
						}
					});
				});
		</script>
	</head>
	
	<body>
		<div class="container">
			<div class="header"><h3 class="text-muted">SNAP Build dashboard<h3></div>
						<div class="bs-callout failed project-summary failed">
							<h3>snap</h3>
							<span class="success">Build Successful</span>	
							<span class="failed">Test Failed</span>	
						</div>

						<div class="bs-callout project-summary success">
							<h3>snapr</h3>
							<span class="failed">Build Successful</span>	
							<span class="failed">Test Successful</span>	
						</div>

				<ul class="nav nav-tabs" id="project-tabs">
				</ul>

				<div class="builds">
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
			<div class="footer">&copy Stanford SNAP</div>
		</div>
	</body>
</html>
