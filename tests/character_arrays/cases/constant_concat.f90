implicit none
character(3),parameter::a="a"//"b"
character(4)::b(2)=a//"c"
print *,b=="ab c",b
end
