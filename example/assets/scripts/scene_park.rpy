# Scene 3 — 공원의 소라
# 캐릭터: 소라 (sora), 표정: normal / happy / sad, 대사 10줄

label park:
    scene bg_park with dissolve

    "저녁 공원. 가로등이 하나둘 켜지고 바람이 살짝 불어온다."

    show sora normal with dissolve

    sora "여기 자주 와? 나는 저녁마다 산책하는 편이거든."       # 1

    sora "이 시간대 공원이 제일 좋아. 사람도 적고 조용해서."   # 2

    show sora sad with dissolve

    sora "요즘 좀 복잡한 일이 있어서 머리 식히러 나왔어."      # 3

    sora "친구랑 오해가 생겼는데... 어떻게 풀어야 할지 모르겠어." # 4

    sora "연락하려고 몇 번 폰 들었다가 그냥 내려놨어."         # 5

    show sora normal with dissolve

    sora "그냥 시간이 해결해 주겠지, 하는 생각도 있고."        # 6

    sora "근데 이렇게 두는 게 맞는 건지 모르겠어."             # 7

    show sora happy with dissolve

    sora "네 얘기 들으니까 조금 마음이 편해졌어."              # 8

    sora "맞아, 그냥 솔직하게 말하는 게 낫겠다."              # 9

    sora "내일 용기 내서 먼저 연락해볼게. 고마워."             # 10

    hide sora with dissolve
    scene with fade

    "소라는 벤치에서 일어나 밝아진 표정으로 걸음을 옮겼다."
    return
