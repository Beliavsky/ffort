implicit none
character(2),parameter::a(2)=["ab","cd"]
character(3),parameter::b(2)=a//"!"
print *,b
end
