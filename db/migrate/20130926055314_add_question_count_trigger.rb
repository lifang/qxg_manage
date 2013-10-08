class AddQuestionCountTrigger < ActiveRecord::Migration
  def up

    sql = <<-_SQL
    DROP TRIGGER IF EXISTS get_question_count_insert
    ^
    create TRIGGER get_question_count_insert AFTER INSERT ON questions FOR EACH ROW

BEGIN
  SET @question_count_insert = (SELECT count(*) FROM questions AS question_count WHERE round_id = NEW.round_id);
  UPDATE rounds SET rounds.questions_count = @question_count_insert WHERE rounds.id=NEW.round_id;
END
    ^
DROP TRIGGER IF EXISTS get_question_count_delete
    ^
    create TRIGGER get_question_count_delete AFTER DELETE ON questions FOR EACH ROW

BEGIN
  SET @question_count_delete = (SELECT count(*) FROM questions AS question_count WHERE round_id = OLD.round_id);
  UPDATE rounds SET rounds.questions_count = @question_count_delete WHERE rounds.id=OLD.round_id;
END

    _SQL
    sql.split('^').each do |stmt|
      execute(stmt) if (stmt.strip! && stmt.length > 0)
    end

  end

  def down
    sql = <<-_SQL
    DROP TRIGGER IF EXISTS get_question_count_insert;
    DROP TRIGGER IF EXISTS get_question_count_delete;
    _SQL
    sql.split(';').each do |stmt|
      execute(stmt) if (stmt.strip! && stmt.length > 0)
    end
  end
end
