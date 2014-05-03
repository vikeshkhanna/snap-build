<?php
$page = $_SERVER['PHP_SELF'];
$sec = "30";
?>
<html>
	<head>
		<title>SNAP build dashboard</title>
		<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">
		<link rel="stylesheet" href="css/main.css">
		<link rel="stylesheet" href="css/docs.min.css">
		<meta http-equiv="refresh" content="<?php echo $sec?>;URL='<?php echo $page?>'">
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
							<th>Build Status</th>
							<th>Test Status</th>
							<th>Logs</th>
						</tr>
						<?php
							include('db/sqlitedb.php');
							$db = get_db_handle();
							$db->beginTransaction();
							$comm = "SELECT * FROM snapr ORDER BY tstart DESC LIMIT 10;";
							$result = $db->prepare($comm);
							$result->execute();
							$db->commit();
							$rows = $result->fetchAll(PDO::FETCH_ASSOC);

							foreach($rows as $row) {		
								$buildStatus = intval($row['build_status']);
								$testStatus = intval($row['test_status']);
								$statusStr = array(
								    -1 => "Queued",
								     2 => "In Progress",
								     0 => "Successful",
								     1 => "Failed"
							      	);

								$statusClass = array(
									-1 => "queued",
									2 => "progress",
									0 => "success",
									1 => "failed"
								);

								if ($buildStatus==-1 || $buildStatus==2 || $testStatus==-1 || $testStatus==2) {
									echo "<tr class='progress'>";
								} else if($buildStatus==0 && $testStatus==0) {
									echo "<tr class='success'>";
								} else {
									echo "<tr class='failed'>";								
								}

								echo "<td>".$row['id']."</td>";
								echo "<td>".date('Y-m-d H:i:s', $row['tstart'])."</td>";
								echo "<td>".date('Y-m-d H:i:s', $row['tend'])."</td>";
								echo "<td class='".$statusClass[$buildStatus]."'>".$statusStr[$buildStatus]."</td>";
								echo "<td class='".$statusClass[$testStatus]."'>".$statusStr[$testStatus]."</td>";
								echo "<td><a href='logs/".$row['logs']."' target='_blank'>".$row['logs']."</a></td>";
								echo "</tr>";
							}
						?>
					</table>
				</div>
			<div class="footer">&copy Stanford SNAP</div>
		</div>
	</body>
</html>
