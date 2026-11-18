program purity_test
implicit none
real(8)::aa(2,2),bb(2,2)
aa=2.0d0
bb=3.0d0
print *,compute(aa,bb)
contains
simple real(8) function compute(xx,yy) result(rr)
real(8),intent(in)::xx(:,:),yy(:,:)
rr=sum(matmul(matrix_b=yy,matrix_a=xx))+real(size(xx))+sqrt(4.0d0)+log(exp(1.0d0))+erfc(0.0d0)
end function

end program
