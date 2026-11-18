program p
implicit none
integer,save :: a(2,0)=7
a=9
print *,size(a),sum(a)
end program
