program p
implicit none
integer,target::a(3,2)
integer,pointer::view(:,:)
integer::b(2,2)
view=>a
b=view([1,2],:)
end program
