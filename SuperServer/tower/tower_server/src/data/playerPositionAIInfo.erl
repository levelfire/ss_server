-module(playerPositionAIInfo).
-export([get_data/1,get_indexs/0]).
get_data(1000) -> {playerPositionAIInfo,1000,<<"郑容和">>,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
get_data(1001) -> {playerPositionAIInfo,1001,<<"马里奥">>,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
get_data(1002) -> {playerPositionAIInfo,1002,<<"酋长">>,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0};
get_data(1003) -> {playerPositionAIInfo,1003,<<"鹿晗">>,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0};
get_data(1004) -> {playerPositionAIInfo,1004,<<"艾吉奥">>,0,0,0,0,0,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0};
get_data(1005) -> {playerPositionAIInfo,1005,<<"毒药">>,0,0,0,0,0,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0};
get_data(1006) -> {playerPositionAIInfo,1006,<<"古烈">>,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0};
get_data(1007) -> {playerPositionAIInfo,1007,<<"少林">>,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0};
get_data(1008) -> {playerPositionAIInfo,1008,<<"冰人">>,0,0,0,0,0,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0};
get_data(1009) -> {playerPositionAIInfo,1009,<<"福尔摩斯">>,0,0,0,0,0,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0};
get_data(1010) -> {playerPositionAIInfo,1010,<<"紫原">>,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
get_data(1011) -> {playerPositionAIInfo,1011,<<"青峰">>,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0};
get_data(1012) -> {playerPositionAIInfo,1012,<<"黄濑">>,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0,0,0,0,0,0};
get_data(1013) -> {playerPositionAIInfo,1013,<<"绿间">>,0,0,0,0,0,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0};
get_data(1014) -> {playerPositionAIInfo,1014,<<"赤司">>,0,0,0,0,0,0,0,0,0,0,0,20,20,20,20,20,0,0,0,0,0};


get_data(_Id) -> [].
get_indexs() -> [1000,1001,1002,1003,1004,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014].
