implicit none
character(2)::a(3)=["ab","cd","ef"]
a=a(3:1:-1)
print *,a
end
