program p
implicit none
integer,parameter::a(1,1)=reshape([1],[1,1])
integer,parameter::b(1,1)=a([1],:)
end program
