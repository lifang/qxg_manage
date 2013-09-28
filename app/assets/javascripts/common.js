/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

function toggleNext(obj){   
    if($(obj).next().css("display")=="none"){
        $(".question_options").hide();
        $(obj).next().show();
    }else{
        $(".question_options").hide();
        $(obj).next().hide();
    }
    
}
function toggleCard(obj, question_id){
    $("#question_" + question_id).toggle();
}