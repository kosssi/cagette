
package react.store;


// it's just easier with this lib
import classnames.ClassNames.fastNull as classNames;
import mui.CagetteTheme.CGColors;
import mui.core.styles.Classes;
import mui.core.styles.Styles;
import react.ReactComponent;
import react.ReactMacro.jsx;
import react.types.*;
import mui.icon.Icon;
import css.JustifyContent;
import css.AlignContent;
import css.Properties;
import css.Overflow;

private typedef HeaderSubCategoryButtonProps = {
	> PublicProps,
	var classes:TClasses;
}

private typedef PublicProps = {
    label:String,
    onclick:Void->Void,
    active:Bool,
    ?colorClass:String,
    ?icon: String,
}

private typedef TClasses = Classes<[
	labelChip,
    icon,
    cagSelect, 
    cagLabelRouge,
    cagBio,
]>

@:acceptsMoreProps
@:publicProps(PublicProps)
@:wrap(Styles.withStyles(styles))
class HeaderSubCategoryButton extends ReactComponentOfProps<HeaderSubCategoryButtonProps> {
    
    public static function styles(theme:mui.CagetteTheme):ClassesDef<TClasses> {
		return {
            icon : {
                fontSize: "inherit",
                overflow: Visible,
                margin: 4,
            },
            labelChip : {
                fontSize: "0.75rem",
                margin: "5px 5px",
                padding: "5px 5px",

                backgroundColor: CGColors.White,    
                borderRadius: 16,
                textDecoration: "none",
                display: "inline-block",

                transition: "all 0.5s ease",

                "&:hover" : {
                    backgroundColor: "#DCDCDC",//untyped color('#FFFFF').darken(10).hex(),
                },
            },

            cagSelect : {
                color:'#E56403',
            },
            
            cagLabelRouge : {
                color:'#E53909',
            },

            cagBio : {
                color:'#16993B',
            },

		}
	}

    override function render() {
        trace(props.active);
        var classes = props.classes;
        var linkClasses = classNames({
			'${classes.labelChip}': true,
            '${classes.cagSelect}': props.active,
		});
        
        var iconClasses = classNames({
            '${props.icon}' : true,
            '${classes.icon}': true,
        });

        var others = react.ReactMacro.getExtraProps(props);
        //TODO replace by Chip composant instead?
       // <Chip color="primary" icon={<FaceIcon />} />

       var icon = (props.icon != null) ? jsx('<Icon component="i" className=${iconClasses} /> '): null;
        return jsx('
            <a onClick=${props.onclick} className=${linkClasses} {...others}>
                ${icon}${props.label}
            </a>
        ');
    }
}
