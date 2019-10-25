/*Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using ContainerMVC.Models;
using ContainerMVC.DataAccess;

namespace ContainerMVC.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;

        private BooksContext bookDB = new BooksContext();

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Books()
        {
            bookDB.ConfigureAwait(true);
            return View(bookDB.Books.ToList());
        }

        public ActionResult Create()
        {
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(include: "Id,Title,AuthorFirstName,AuthorLastName,AvgCustomerReviews,Price,BookLanguage,Publisher")]Book book)
        {
            try
            {
                bookDB.Books.Add(book);
                bookDB.SaveChanges();
                return RedirectToAction("Books");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("Add", string.Format("Unable to save changes. Try again, and if the problem persists, see your system administrator. Exception:{0}", ex.Message));
            }

            return View(book);
        }

        public ActionResult Edit(int id)
        {
            var book = bookDB.Books.Find(id);

            if( book == null)
            {
                return null; 
            }

            return View(book); 
        }

        public ActionResult Delete(int id)
        {
            var book = bookDB.Books.Find(id);

            if (book == null)
            {
                return null;
            }

            bookDB.Remove(book);
            bookDB.SaveChanges();
            return RedirectToAction("Books");
        }

        [HttpPost, ActionName("Edit")]
        [ValidateAntiForgeryToken]
        public ActionResult EditBook(int id)
        {
            var book = bookDB.Books.Find(id);
            TryUpdateModelAsync<Book>(book).Wait();

            try
            {
                bookDB.SaveChanges();
                return RedirectToAction("Books");
            }
            catch (Exception ex)
            {
                ModelState.AddModelError("Update", string.Format("Unable to save changes. Try again, and if the problem persists, see your system administrator.Exception : {0}", ex.Message));
            }

            return View(book);
        }
    }
}