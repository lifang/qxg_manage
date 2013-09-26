#encoding: utf-8
class AddCountTrigger < ActiveRecord::Migration
  #创建触发器，当rounds表里面记录数目增减的时候，更新chapters表里面的round_count的值
  def up
    sql = <<-_SQL
    DROP TRIGGER IF EXISTS get_round_count_insert
    ^
    create TRIGGER get_round_count_insert AFTER INSERT ON rounds FOR EACH ROW

BEGIN
  SET @round_count_insert = (SELECT count(*) FROM rounds AS round_count WHERE chapter_id = NEW.chapter_id);
  UPDATE chapters SET chapters.round_count = @round_count_insert WHERE chapters.id=NEW.chapter_id;
END
    ^
DROP TRIGGER IF EXISTS get_round_count_delete
    ^
    create TRIGGER get_round_count_delete AFTER DELETE ON rounds FOR EACH ROW

BEGIN
  SET @round_count_delete = (SELECT count(*) FROM rounds AS round_count WHERE chapter_id = OLD.chapter_id);
  UPDATE chapters SET chapters.round_count = @round_count_delete WHERE chapters.id=OLD.chapter_id;
END

    _SQL
    sql.split('^').each do |stmt|
      execute(stmt) if (stmt.strip! && stmt.length > 0)
    end


  end

  def down
    sql = <<-_SQL
    DROP TRIGGER IF EXISTS get_round_count_insert;
    DROP TRIGGER IF EXISTS get_round_count_delete;
    _SQL
    sql.split(';').each do |stmt|
      execute(stmt) if (stmt.strip! && stmt.length > 0)
    end
  end
end
