/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
$(function(){
    // 隐藏弹出框
    $(".close").click(function(){
        $(".second_box").hide();
	$(".second_bg").hide();
        $(".second_content").hide();
    });

    $("tr").each(function(){
        var table = $(this).parents("table");
        var i = table.find("tr").index($(this));
        if(i % 2 ==0 && i != 0){
            $(this).css("background","#F2F6F6");
        }
    });

});

function handleUpload(obj){
    $(obj).parents(".fileBox").find(".fileText_1").val($(obj).val());
}

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


function file_validate(obj){
    var reg =  /.*\.zip/
    var file_name = ($(obj).val());
    if(!reg.test(file_name))
    {
        $("#btn_upload").attr("disabled","true");
        alert("请选择zip题库压缩包");
        $(obj).val("");
    }
    else
        $("#btn_upload").removeAttr("disabled");
    end

}

function show_tag(obj){
    obj.parent(".second_content").show();
    obj.parents(".second_box").show();
    obj.parents(".second_box").prev().show();
}