package react.store;

import Common;
import react.ReactSuspense;
import react.React.Module;
import react.ReactComponent;
import react.ReactType;
import react.ReactMacro.jsx;
import react.ReactSuspense;
import mui.core.CircularProgress;
import mui.core.Grid;
import classnames.ClassNames.fastNull as classNames;
import mui.core.styles.Classes;
import react.store.types.FilteredProductCatalog;
import mui.core.styles.Styles;
import mui.core.Modal;
import js.html.Event;
import mui.core.modal.ModalCloseReason;
import react.store.ProductCatalog;

using Lambda;

typedef ProductCatalogProps = {
	> PublicProps,
	var classes:TClasses;
};

private typedef PublicProps = {
	var categories:Array<CategoryInfo>;
	var catalog:FilteredProductCatalog;
	var vendors : Array<VendorInfo>;
}

private typedef ProductCatalogState = {
	@:optional var modalProduct:Null<ProductInfo>;
	@:optional var modalVendor:Null<VendorInfo>;

	var loading:Bool;
}

private typedef TClasses = Classes<[categories,]>

@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class ProductCatalog extends ReactComponentOf<ProductCatalogProps, ProductCatalogState> {

	public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
			categories : {
                maxWidth: 1240,
                margin : "auto",
                padding: "0 10px",
            },
		}
	}

/*
	static var LazyProductCatalogCategories:ReactType = {
		var p:js.Promise<Module<ReactType>> = new js.Promise(function(resolve:Module<ReactType>->Void, _) {  
			var m:Module<ReactType> = cast new Module(ProductCatalogCategories); 
			resolve(m); 
		});
		React.lazy(function() { return p; });
	}
*/


	function new(p) {
		super(p);
		this.state = {loading:true};
		trace("new catalog");
	}

	override public function render() {
		var classes = props.classes;
		//trace('filter catalog', props.catalog.products.length, props.catalog.category);
		//var loading = jsx('<CircularProgress />');
		//<ReactSuspense fallback=${loading}>
		return jsx('
			<div className=${classes.categories}>
			   <ProductModal 	product=${state.modalProduct}
								vendor=${state.modalVendor}
								onClose=${onModalCloseRequest} />
			  <ProductCatalogCategories categories=${props.categories} catalog=${props.catalog} vendors=${props.vendors} openModal=${openModal} />
			</div>
    	');
	}

	function openModal(product:ProductInfo, vendor:VendorInfo) {
        setState({modalProduct:product, modalVendor:vendor}, function() {trace("modal opened");});
    }

    function onModalCloseRequest(event:js.html.Event, reason:ModalCloseReason) {
        setState({modalProduct:null, modalVendor:null}, function() {trace("modal closed");});
    }

}
