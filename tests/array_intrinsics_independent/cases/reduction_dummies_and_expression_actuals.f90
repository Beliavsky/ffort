program array_intrinsic_oracle
implicit none
integer :: aa(-1:1,4:5)
aa(:,4)=2
aa(:,5)=3
print *,work(aa),work(aa(1:-1:-1,5:4:-1)+1)
contains
integer function work(xx) result(answer)
integer,intent(in) :: xx(-4:,7:)
answer=sum(xx)+sum(maxval(xx,1))+sum(minval(xx,2))
end function
end program
