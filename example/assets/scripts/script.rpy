# Example Ren'Py script for renpy-flutter demo.

label start:
    scene bg_room with dissolve

    "어두운 방에 빛이 들어오기 시작한다."

    show eileen happy with dissolve

    e "안녕하세요! 저는 에일린이에요."
    e "오늘은 정말 좋은 날이에요."

    $ visited = True

    menu:
        "어떤 이야기를 들으실래요?":
            jump story_a
        "그냥 끝낼게요":
            jump ending

label story_a:
    e "좋아요! 모험 이야기를 해드릴게요."

    show eileen excited with dissolve

    e "옛날에 용감한 여행자가 있었어요..."
    e "그녀는 세상의 끝까지 여행했답니다."

    menu:
        "더 들려주세요":
            jump story_more
        "여기서 멈춰요":
            jump ending

label story_more:
    e "여행자는 결국 행복한 결말을 맞이했어요."
    e "그녀의 이야기는 지금도 전해진답니다."
    jump ending

label ending:
    hide eileen with dissolve
    scene with fade

    "이야기가 끝났습니다."
    "즐거운 시간이 되셨길 바랍니다."
    return
