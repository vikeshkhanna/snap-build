<html>
	<head>
		<title>SNAP build dashboard</title>
		<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
		<link rel="stylesheet" href="main.css">
		<link rel="stylesheet" href="docs.min.css">
	</head>
	
	<body>
		<div class="container">
			<div class="header"><h3 class="text-muted">SNAP Build dashboard<h3></div>
				<div class="row">
					<div class="col-md-6">
						<div class="bs-callout bs-callout-info">
							<h4>Latest Hourly Build Status</h4>
							<span>Successful</span>	
						</div>
					</div>

					<div class="col-md-6">
						<div class="bs-callout bs-callout-warning">
							<h4>Latest Unit Test Status</h4>
							<span>Failed</span>	
						</div>
					</div>
				</div>

				<div class="builds">
					<table class="table">
						<tr>
							<th>Build Number</th>
							<th>Start Time</th>
							<th>End Time</th>
							<th>Status</th>
							<th>Logs</th>
						</tr>
						<?php  
							include('sqlitedb.php');
							$db = get_db_handle();
							$db->beginTransaction();
							$comm = "SELECT * FROM status ORDER BY tstart DESC LIMIT 10;";

							$result = $db->prepare($comm);
							$result->execute();
							$db->commit();
							$rows = $result->fetchAll(PDO::FETCH_ASSOC);

							foreach($rows as $row) {		
								echo "<tr>";
								echo "<td>".$row['id']."</td>";
								echo "<td>".$row['tstart']."</td>";
								echo "<td>".$row['tend']."</td>";
								echo "<td>".$row['status']."</td>";
								echo "<td>".$row['logs']."</td>";
								echo "</tr>";
							}
						?>
					</table>
				</div>
			<div class="footer">&copy Stanford SNAP</div>
		</div>
	</body>
</html>
