<? 
require_once('Connections/pamconnection.php'); 
require_once('pro/str_convert.php');
require_once('pro/authentication.php');
$authentication->authenticate();
?>
<!DOCTYPE html>
<html lang="en" xml:lang="en">
<head>
<? include 'prefix.php';?>
<? /*
<meta property="og:type" content="website" />
<meta property="og:image" itemprop="image" content="<?=ROOT_F?>photo/5d2d39d24c9a4.jpg"/>  
<meta property="og:title" content="ABABABABABABA"/>  
<meta property="og:description" content="Jonathan Test Site, please ignore if you are vivian toh."/>              
*/

if(!empty($_GET['id'])){
	$pd = readFirst($pamconnection, "product", "id='".$_GET['id']."'");
}

?>

<meta property="og:site_name" content="http://fyhonlinestore.com.my">
<meta property="og:title" content="<? echo $pd['product_name']?>" />
<meta property="og:description" content="Great deal! View this product!" />
<meta property="og:image" itemprop="image" content="<?=ROOT_F.$pd['photo1']?>">
<meta property="og:type" content="website" />
         



</head>
<body>
<div class="center">
	<? include("header.php");?>
    <div class="container">
        <div class="row">
			<? include("filter.php");?>
			<? include("product.php");?>
		</div>
    </div>
</div>
<? include("suffix.php");?>
</div>
</body>
</html>
