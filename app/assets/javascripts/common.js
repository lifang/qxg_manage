/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

function toggleNext(obj){   //展开，显示题目选项
    if($(obj).next().css("display")=="none"){
        $(".question_options").hide();
        $(obj).next().show();
    }else{
        $(".question_options").hide();
        $(obj).next().hide();
    }
    
}
function toggleCard(obj, question_id){ //展开显示知识卡片
    $("#question_" + question_id).toggle();
}

function sConClose(){  // 隐藏弹出框
    $(".second_content").hide();
}