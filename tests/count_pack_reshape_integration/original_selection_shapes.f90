! Exact original utility bodies; only module, DP and driver are supplied.
module original_utility_selection_shapes
implicit none
integer,parameter::dp=kind(1.0d0)
contains
function true_pos_func(tf) result(ipos)
! return in ipos the positions of the true elements in tf(:)
logical, intent(in) :: tf(:)
integer             :: ipos(count(tf))
integer             :: i,j
j = 0
do i=1,size(tf)
   if (tf(i)) then
      j = j + 1
      ipos(j) = i
   end if
end do
end function true_pos_func
function positive_int_vec(ivec) result(jvec)
integer, intent(in) :: ivec(:)
integer             :: jvec(count(ivec>0))
jvec = pack(ivec,ivec>0)
end function positive_int_vec
function matrix_from_vec(xvec) result(xmat)
! convert a vector of N elements to an Nx1 matrix
real(kind=dp), intent(in) :: xvec(:)
real(kind=dp)             :: xmat(size(xvec),1)
xmat(:,1) = xvec
end function matrix_from_vec
function vector(xmat) result(xvec)
! convert a matrix to a vector
real(kind=dp), intent(in) :: xmat(:,:)
real(kind=dp)             :: xvec(size(xmat))
xvec = reshape(xmat,(/size(xmat)/))
end function vector
end module
program combined_selection_shapes
use original_utility_selection_shapes
implicit none
integer::iv(6)=[-3,0,2,4,-1,6],empty_int(0),i
real(dp)::ordered(2,3)
! Both original COUNT-dependent results and the original matrix/vector pair.
print *,true_pos_func(iv>0)
print *,positive_int_vec(iv)
print *,vector(matrix_from_vec(dble(positive_int_vec(iv))))
print *,sum(vector(matrix_from_vec(dble(positive_int_vec(iv)))))
print *,dot_product(vector(matrix_from_vec(dble(positive_int_vec(iv)))), &
                    vector(matrix_from_vec(dble(positive_int_vec(iv)))))
! COUNT result -> PACK -> RESHAPE -> original VECTOR.
print *,vector(reshape(dble(pack(true_pos_func(iv>0),true_pos_func(iv>0)>3)),[1,2]))
! Original positive_int_vec itself uses PACK; feed that result into RESHAPE.
ordered=reshape(dble(positive_int_vec([1,2,3,4,5,6])),[2,3],order=[2,1])
print *,vector(ordered)
print *,sum(ordered,dim=1)
print *,sum(ordered,dim=2)
print *,matmul(reshape(dble(positive_int_vec([1,2,3,4])),[2,2]),[2.0_dp,3.0_dp])
print *,sum(vector(matrix_from_vec(dble(true_pos_func(iv>0)))))
! Reversed sections remain ordinary actuals for all original bodies.
print *,vector(matrix_from_vec(dble(positive_int_vec(iv(6:1:-1)))))
print *,vector(ordered(2:1:-1,3:1:-1))
! Empty COUNT/PACK results survive nested calls and rank changes.
print *,size(vector(matrix_from_vec(dble(positive_int_vec(empty_int)))))
print *,size(vector(matrix_from_vec(dble(positive_int_vec([-3,0,-1])))))
print *,size(vector(reshape(dble(positive_int_vec(empty_int)),[0,2])))
print *,sum(vector(matrix_from_vec(dble(true_pos_func(empty_int>0)))))
! Repeated calls change COUNT-derived shapes without retaining stale storage.
do i=0,3
  print *,size(vector(matrix_from_vec(dble(positive_int_vec([i-2,i-1,i])))))
end do
end program
