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

function upload(onj)
{
    if(confirm("导入将覆盖现有题目，确认导入？"))
    {
        $('.submit_btn').click();
    }
}

function file_validate(obj){
    var reg =  /.*\.zip/
    var file_name = ($(obj).val());
    if(!reg.test(file_name))
    {
        $("#btn_upload").attr("disabled","true");
        alert("请选择zip题库压缩包");
        $(obj).val("");
        $(obj).parents(".fileBox").find(".fileText_1").val($(obj).val());
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
function hide_tab(obj){
    obj.parent(".second_content").hide();
    obj.parents(".second_box").hide();
    obj.parents(".second_box").prev().hide();
}

function MdToHtml(obj){
   var mdContent = $.trim($("#knowledge_card_description").val());
   var previewTag = $(obj).parent().next();
   if(mdContent!=""){
     $.ajax({
         url: "/md_to_html",
         type: "POST",
         dataType: "text",
         data:{content:mdContent},
         success:function(data){
             previewTag.html(data)
         },
         error:function(data){
            alert("error")
         }
     })
   }
}

function checkFilesize(obj){
    var edit_img_val = $("#"+obj).val();
    if(edit_img_val!=""){
        var input_e = document.getElementById(obj);
        var file_size_e = input_e.files[0].size;
        if(file_size_e > 1024*1024){
            alert("图片大小不能超过1MB！");
            return false;
        }

        var pattern = new RegExp("[`~!@#$^&*()=|{}':;',\\[\\].<>/?~！@#￥……&*（）——|{}【】‘；：”“'。，、？]")
        var img_name = edit_img_val.substring(edit_img_val.lastIndexOf("\\")).toLowerCase();
        var g_name = img_name.substring(1,img_name.length);
        if(pattern.test(g_name.split(".")[0])){
            alert(g_name+"不能包含特殊字符!");
            return false;
        }
        var edit_img_suff = edit_img_val.substring(edit_img_val.lastIndexOf('.') + 1).toLowerCase();
        if(edit_img_suff == "jpg" || edit_img_suff == "png" || edit_img_suff == "jpeg"){
        }else{
            alert("图片格式不对!");
            return false;
        }
    }
}