implicit none
character(0)::x(2)
x=''
print *,size(x([2,1,2])),len(x([2,1]))
end
