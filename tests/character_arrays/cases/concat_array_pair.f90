implicit none
character(2)::a(2)=["ab","cd"]
character::b(2)=["x","y"]
print *,a//b,b//a
end
